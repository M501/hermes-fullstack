#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
vision_fallback.py - OpenAI-compatible vision proxy (port 9225).

  PRIMARY : MiMo V2.5 Free via UniClaudeProxy (127.0.0.1:9224, OpenAI format)
  FALLBACK: Qwen3.5-9B local via Ollama NATIVE /api/chat (127.0.0.1:11434)
            with think=true (max reasoning quality, user preference) and
            keep_alive=60s (model unloads from VRAM after a minute idle).

Fallback triggers (any of):
  - HTTP status >= 400 from MiMo (403/429/404/500/502 ...)
  - network error / connection refused / timeout
  - response body is not valid JSON, or JSON contains "error" key

stdio only, no deps. Run: python vision_fallback.py
"""
import json
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MIMO_URL = "http://127.0.0.1:9224/v1/chat/completions"
MIMO_MODEL = "mimo-v2.5-free"
OLLAMA_CHAT_URL = "http://127.0.0.1:11434/api/chat"
OLLAMA_MODEL = "qwen3.5:9b"
MIMO_TIMEOUT = 120      # MiMo может долго думать
OLLAMA_TIMEOUT = 600    # локальная модель: первый вызов грузит 6.6GB в VRAM
HOST, PORT = "127.0.0.1", 9225


def log(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


class BackendError(Exception):
    def __init__(self, backend, status, detail):
        self.backend = backend
        self.status = status
        self.detail = detail


# ---------- MiMo (OpenAI format) ----------

def try_mimo(payload, timeout):
    p = dict(payload)
    p["model"] = MIMO_MODEL
    req = urllib.request.Request(MIMO_URL, data=json.dumps(p).encode("utf-8"),
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            raw = r.read()
            status = r.status
    except urllib.error.HTTPError as e:
        raise BackendError("mimo", e.code, e.read()[:500].decode("utf-8", "replace"))
    except Exception as e:
        raise BackendError("mimo", 0, str(e))
    if status >= 400:
        raise BackendError("mimo", status, raw[:500].decode("utf-8", "replace"))
    try:
        d = json.loads(raw.decode("utf-8", "replace"))
    except Exception:
        raise BackendError("mimo", status, "non-JSON body")
    if isinstance(d, dict) and d.get("error"):
        raise BackendError("mimo", status, json.dumps(d["error"])[:500])
    return d


# ---------- Ollama (native /api/chat, think=false) ----------

def build_ollama_messages(payload):
    """Convert OpenAI messages (text + image_url data URIs) to Ollama native."""
    msgs = []
    found_image = False
    for m in payload.get("messages", []):
        c = m.get("content")
        images, text_parts = [], []
        if isinstance(c, str):
            if c.startswith("data:image"):
                images.append(c.split(",", 1)[1])
            else:
                text_parts.append(c)
        elif isinstance(c, list):
            for part in c:
                if not isinstance(part, dict):
                    continue
                if part.get("type") == "image_url":
                    u = part.get("image_url", {}).get("url", "") if isinstance(part.get("image_url"), dict) else ""
                    if u.startswith("data:image"):
                        images.append(u.split(",", 1)[1])
                        found_image = True
                    elif u:
                        text_parts.append(f"[image: {u}]")
                elif part.get("type") == "text":
                    text_parts.append(part.get("text", ""))
        content = "\n".join(text_parts).strip()
        if not content and images:
            content = "Describe this image."
        nm = {"role": m.get("role", "user"), "content": content}
        if images:
            nm["images"] = images
        msgs.append(nm)
    return msgs


def try_ollama(payload, timeout):
    body = {
        "model": OLLAMA_MODEL,
        "messages": build_ollama_messages(payload),
        "stream": False,
        "think": True,            # max reasoning: better vision quality (user choice)
        "keep_alive": 60,         # unload from VRAM after 60s idle (no 24/7 hog)
    }
    opts = {}
    # thinking burns tokens on reasoning: raise the cap so the final answer
    # is not cut off (finish=length, empty content). 4096 = max reasoning.
    want = int(payload["max_tokens"]) if payload.get("max_tokens") else 1024
    opts["num_predict"] = max(want, 4096)
    # default num_ctx=262144 -> 10GB + 48% CPU offload on 8GB VRAM.
    # 16384 is plenty for screenshots and keeps the model fully/mostly on GPU.
    opts["num_ctx"] = 16384
    if payload.get("temperature") is not None:
        opts["temperature"] = float(payload["temperature"])
    body["options"] = opts
    req = urllib.request.Request(OLLAMA_CHAT_URL, data=json.dumps(body).encode("utf-8"),
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            raw = r.read()
            status = r.status
    except urllib.error.HTTPError as e:
        raise BackendError("ollama", e.code, e.read()[:500].decode("utf-8", "replace"))
    except Exception as e:
        raise BackendError("ollama", 0, str(e))
    try:
        d = json.loads(raw.decode("utf-8", "replace"))
    except Exception:
        raise BackendError("ollama", status, "non-JSON body")
    if isinstance(d, dict) and d.get("error"):
        raise BackendError("ollama", status, json.dumps(d["error"])[:500])
    return d


def ollama_to_openai(d):
    """Convert Ollama native /api/chat response to OpenAI chat.completion."""
    msg = d.get("message", {}) or {}
    content = msg.get("content", "") or ""
    usage = {}
    if d.get("prompt_eval_count") is not None:
        usage = {
            "prompt_tokens": d.get("prompt_eval_count", 0),
            "completion_tokens": d.get("eval_count", 0),
            "total_tokens": d.get("prompt_eval_count", 0) + d.get("eval_count", 0),
        }
    return {
        "id": f"chatcmpl-local-{int(time.time() * 1000)}",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": OLLAMA_MODEL,
        "choices": [{
            "index": 0,
            "message": {"role": "assistant", "content": content},
            "finish_reason": "stop" if d.get("done_reason") == "stop" else (d.get("done_reason") or "stop"),
        }],
        "usage": usage,
    }


# ---------- HTTP handler ----------

class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _send(self, status, ctype, body):
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "close")
        self.end_headers()
        try:
            self.wfile.write(body)
        except Exception:
            pass

    def _send_json(self, status, obj):
        self._send(status, "application/json", json.dumps(obj).encode("utf-8"))

    def do_GET(self):
        if self.path == "/healthz":
            self._send(200, "text/plain", b"ok")
        elif self.path == "/v1/models":
            self._send_json(200, {"object": "list", "data": [
                {"id": MIMO_MODEL, "object": "model"},
                {"id": OLLAMA_MODEL, "object": "model"},
            ]})
        else:
            self._send_json(404, {"error": {"message": f"not found: {self.path}"}})

    def do_POST(self):
        if self.path != "/v1/chat/completions":
            self._send_json(404, {"error": {"message": f"not found: {self.path}"}})
            return
        try:
            length = int(self.headers.get("Content-Length", 0))
            raw = self.rfile.read(length) if length else b"{}"
            payload = json.loads(raw.decode("utf-8"))
        except Exception as e:
            log(f"bad request: {e}")
            self._send_json(400, {"error": {"message": "bad request body"}})
            return

        t0 = time.time()
        has_image = any(
            isinstance(m.get("content"), list) and
            any(isinstance(x, dict) and x.get("type") == "image_url" for x in m.get("content"))
            for m in payload.get("messages", [])
        )

        # 1) MiMo first - always priority when alive
        try:
            d = try_mimo(payload, MIMO_TIMEOUT)
            log(f"MiMo OK   img={has_image} {round(time.time()-t0,1)}s")
            self._send_json(200, d)
            return
        except BackendError as e:
            log(f"MiMo FAIL {e.backend} status={e.status} img={has_image} "
                f"{round(time.time()-t0,1)}s -> {e.detail[:180]!r} -> fallback")
        except Exception as e:
            log(f"MiMo CRASH {e!r} -> fallback")

        # 2) Ollama local (native API, thinking OFF)
        try:
            d = try_ollama(payload, OLLAMA_TIMEOUT)
            log(f"OLLAMA OK img={has_image} {round(time.time()-t0,1)}s")
            self._send_json(200, ollama_to_openai(d))
        except BackendError as e:
            log(f"OLLAMA FAIL {e.backend} status={e.status} {e.detail[:180]!r}")
            self._send_json(503, {"error": {"message": "both vision backends failed"}})
        except Exception as e:
            log(f"OLLAMA CRASH {e!r}")
            self._send_json(503, {"error": {"message": f"ollama backend crash: {e}"}})


if __name__ == "__main__":
    # Single-instance guard: Windows SO_REUSEADDR lets two processes bind the
    # same port silently (watchdog + manual start = duplicate listeners).
    # If something already answers on :9225, refuse to start.
    import socket
    probe = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    probe.settimeout(1)
    try:
        if probe.connect_ex((HOST, PORT)) == 0:
            log("another instance already listening - exiting")
            raise SystemExit(0)
    finally:
        probe.close()
    srv = ThreadingHTTPServer((HOST, PORT), Handler)
    log(f"vision_fallback listening on {HOST}:{PORT} (MiMo -> {OLLAMA_MODEL})")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass