# Hermes FullStack

> **Быстрый перенос всей инфраструктуры Hermes на новую машину.**
> Клонируй → запусти `setup.bat` → отредактируй ключи → всё работает.

## Что внутри

| Компонент | Порт | Описание |
|-----------|------|----------|
| **OpenCode Proxy** | `:9224` | FastAPI-прокси → OpenCode Zen (DeepSeek/MiMo/Nemotron/Muse Spark — бесплатно) |
| **Vision Fallback** | `:9225` | MiMo V2.5 → Ollama Qwen3.5-9B (автопереключение при ошибках) |
| **SearXNG** | `:8888` | Локальный поисковик (DDG, Bing, Startpage, Wikipedia) |
| **Ollama** | `:11434` | Локальные LLM (vision fallback) |
| **Hermes Agent** | — | AI-агент с Telegram-шлюзом, голосовым, cron, memory |
| **Watchdog** | — | Автозапуск + автоперезапуск всех сервисов |

## Быстрый старт (новая машина)

### 1. Клонируй репозиторий
```cmd
git clone <this-repo> C:\AI\hermes-fullstack
```

### 2. Запусти setup
```cmd
cd C:\AI\hermes-fullstack
setup.bat
```

Что делает `setup.bat`:
- Проверяет Python 3.13+, git
- Устанавливает Hermes Agent
- Клонирует и настраивает OpenCode Proxy (port 9224)
- Копирует Vision Fallback (port 9225)
- Устанавливает SearXNG конфиг (port 8888)
- Применяет конфигурацию Hermes с фиксами
- Ставит лаунчер на рабочий стол

### 3. Заполни ключи
Отредактируй `C:\AI\HERMES\.hermes\.env`:
```env
TELEGRAM_BOT_TOKEN=ваш_токен
TELEGRAM_ALLOWED_CHAT=ваш_chat_id
```

Все остальные ключи опциональны — прокси работает бесплатно без ключей.

### 4. Установи Ollama (для vision fallback)
Скачай с https://ollama.com/download, затем:
```cmd
ollama pull qwen3.5:9b
```

### 5. Запускай!
Дважды кликни **"Hermes + MiMo.bat"** на рабочем столе.

## Структура

```
hermes-fullstack/
├── setup.bat                      # Главный установщик (1 клик)
├── launchers/
│   └── Hermes + MiMo.bat         # Лаунчер всей стеки
├── proxy/                         # (клонируется из opencode-hermes-adapter)
│   ├── app/main.py               # FastAPI прокси
│   ├── config.json               # Конфиг моделей (source of truth)
│   ├── sync_hermes_config.py     # Синхронизация config.yaml
│   ├── get_model_ctx.py          # Вывод текущей модели
│   └── requirements.txt
├── vision-fallback/
│   └── vision_fallback.py        # MiMo → Ollama fallback proxy
├── watchdog/
│   └── watchdog.ps1              # Супервизор всех сервисов
├── config-templates/
│   ├── config.yaml               # Hermes конфиг (с фиксами)
│   └── .env                      # Шаблон переменных окружения
├── webstack-config/
│   └── settings.yml              # SearXNG конфиг (DDG+ Bing+Wikipedia)
└── README.md
```

## Что отредактировано (фиксы)

### 1. STT — автоопределение языка
```
stt.language: ""          # было "en" → ломало русскую речь
stt.local.language: ""    # тоже пустое
```
Whisper large-v3 сам определяет язык (русский, английский, и т.д.).

### 2. Vision — fallback с MiMo на Ollama
Порт `:9225` — если MiMo отвечает 4xx/5xx/таймаут, автоматически
переключается на локальный Qwen3.5-9B через Ollama.

### 3. Watchdog — полный мониторинг
Следит за 4 сервисами (:9224, :9225, :8888, :11434).
Автоперезапуск при падении + circuit breaker (макс 3 перезапуска за 5 мин).

### 4. Proxy — reasoning xhigh
Модель MiMo V2.5 Free с reasoning effort: xhigh (максимальное рассуждение).

### 5. SearXNG — локальный поиск
Настроен на DDG, Bing, Wikipedia, Startpage, Brave, Mojeek.
Язык по умолчанию: ru. Без captchas (локальный инстанс).

## Порты

```
:9224  — OpenCode Proxy (главный мозг)
:9225  — Vision Fallback (MiMo + Ollama)
:8888  — SearXNG (веб-поиск)
:11434 — Ollama (локальные LLM)
```

## Для разработчиков

### Добавить новый провайдер
Отредактируй `proxy/config.json` → `providers` → добавь секцию.
Затем перезапусти лаунчер (sync_hermes_config.py обновит config.yaml).

### Переключить модель
В `proxy/config.json` измени:
```json
"models": { "opencode": "opencode/<new-model-id>" },
"model_context": { "<new-model-id>": <context_length> }
```

### Ручной запуск отдельного сервиса
```cmd
REM Только прокси
C:\AI\hermes-proxy\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 9224

REM Только vision fallback
C:\AI\hermes-proxy\.venv\Scripts\python.exe C:\AI\vision-fallback\vision_fallback.py

REM Только SearXNG
cd C:\AI\ecc-final\webstack\searxng-master
..\.venv-searx\Scripts\python.exe -m searx.webapp
```

## Системные требования

- Windows 11 (10 тоже работает)
- Python 3.13+ (с pip)
- Git
- 4+ GB RAM (для Ollama + Qwen3.5-9B)
- GPU (опционально, ускоряет Ollama)

## Дополнительно

- WebStack (исследования): `C:\AI\ecc-final\webstack` — клонируй отдельно
- Hermes Desktop: https://hermes-agent.nousresearch.com
- OpenCode Zen: https://opencode.ai/zen/ (бесплатные модели)
