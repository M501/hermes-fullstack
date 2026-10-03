#
# council3 — MoA preset for the single-model DeepSeek flash stack.
# 3 independent flash "references" (same model, same slots, no tools/system prompt:
# blind, correlation-broken by temperature) feed the aggregator, which is the acting
# model that runs tools and carries the billing.
#
# Run once to (re)install the preset:
#   cd C:/AI/HERMES/.hermes && uv run --with pyyaml python council3_bootstrap.py
#
# One-shot council on external material (scriptable / verifiable):
#   hermes chat -Q --provider moa -m council3 -q "<question + evidence>"
#
# Prove the 3 refs actually ran (raw evidence, not paraphrase):
#   cat C:/AI/HERMES/.hermes/moa-traces/<session_id>.jsonl
#
# Rollback: delete the preset, restore the config backup.
#   hermes moa delete council3
#   cp C:/AI/HERMES/.hermes/config.yaml.bak-council3plus1-* C:/AI/HERMES/.hermes/config.yaml
import yaml

CFG = r"C:/AI/HERMES/.hermes/config.yaml"

PRESET = {
    "reference_models": [
        {"provider": "deepseek", "model": "deepseek-flash"},
        {"provider": "deepseek", "model": "deepseek-flash"},
        {"provider": "deepseek", "model": "deepseek-flash"},
    ],
    "aggregator": {"provider": "deepseek", "model": "deepseek-flash"},
    "enabled": True,
    "max_tokens": 4096,
    "fanout": "user_turn",
    "reference_temperature": 0.6,
    "aggregator_temperature": 0.4,
    "degraded_reference_policy": "loud",
}

if __name__ == "__main__":
    with open(CFG, encoding="utf-8") as f:
        d = yaml.safe_load(f)
    d.setdefault("moa", {}).setdefault("presets", {})["council3"] = PRESET
    d.setdefault("moa", {})["save_traces"] = True
    d["moa"]["trace_dir"] = "C:/AI/HERMES/.hermes/moa-traces"
    with open(CFG, "w", encoding="utf-8") as f:
        yaml.safe_dump(d, f, allow_unicode=True, sort_keys=False)
    with open(CFG, encoding="utf-8") as f:
        back = yaml.safe_load(f)
    assert len(back["moa"]["presets"]["council3"]["reference_models"]) == 3
    assert back["moa"]["presets"]["default"]["aggregator"]["model"] == "deepseek-flash"
    print("OK: council3 = 3 refs + aggregator, default intact")
