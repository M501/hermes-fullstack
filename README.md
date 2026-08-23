# Hermes FullStack

> **AI-ассистент одной кнопкой.** Скачал → кликнул → работает.

## Быстрый старт (для всех)

### Вариант 1: Один файл (самый простой)

1. Скачайте `INSTALL-ONE-CLICK.bat` с [GitHub Releases](https://github.com/M501/hermes-fullstack/releases)
2. Дважды кликните
3. Ждите ~5-10 минут (всё скачается и установится само)
4. Готово!

### Вариант 2: Через GitHub

```cmd
git clone https://github.com/M501/hermes-fullstack.git C:\AI\hermes-fullstack
cd C:\AI\hermes-fullstack
setup.bat
```

### Вариант 3: Полный установщик

1. Скачайте архив с [Releases](https://github.com/M501/hermes-fullstack/releases)
2. Распакуйте в любую папку
3. Дважды кликните `setup.bat`

## Что устанавливается

| Компонент | Порт | Описание |
|-----------|------|----------|
| **Hermes Agent** | — | AI-ассистент с Telegram, голосовым, памятью |
| **OpenCode Proxy** | `:9224` | Бесплатные нейросети (MiMo, DeepSeek, Nemotron) |
| **Vision Fallback** | `:9225` | Распознавание картинок (MiMo → Ollama) |
| **SearXNG** | `:8888` | Локальный поиск (DDG, Bing, Wikipedia) |
| **Watchdog** | — | Автозапуск и перезапуск сервисов |

## Что нужно от пользователя

- **Windows 10/11**
- **Интернет** (для скачивания)
- **~2 GB места на диске**
- **Telegram бот** (опционально — создать через @BotFather)

## После установки

1. **Telegram бот**: Напишите в Telegram [@BotFather](https://t.me/BotFather), создайте бота, скопируйте токен
2. **Ollama** (для распознавания картинок): Скачайте с [ollama.com](https://ollama.com/download), затем в командной строке:
   ```
   ollama pull qwen3.5:9b
   ```
3. **Запуск**: Дважды кликните **"Hermes + MiMo.bat"** на рабочем столе

## Структура

```
hermes-fullstack/
├── INSTALL-ONE-CLICK.bat     ← ОДИН ФАЙЛ ДЛЯ ВСЕХ (скачать и кликнуть)
├── INSTALL.bat               ← Полный установщик (с проверкой Python/Git)
├── setup.bat                 ← Тихая установка (для продвинутых)
├── launchers/
│   └── Hermes + MiMo.bat    ← Лаунчер на рабочий стол
├── config-templates/
│   ├── config.yaml           ← Конфиг Hermes с фиксами
│   └── .env                  ← Шаблон ключей
├── vision-fallback/
│   └── vision_fallback.py    ← Vision proxy (MiMo → Ollama)
├── watchdog/
│   └── watchdog.ps1          ← Супервизор сервисов
├── webstack-config/
│   └── settings.yml          ← SearXNG конфиг
├── scripts/
│   ├── setup-searxng.bat     ← Установка SearXNG
│   ├── install-watchdog.ps1  ← Регистрация watchdog
│   └── healthcheck.bat       ← Проверка здоровья
└── README.md
```

## Порты

```
:9224  — OpenCode Proxy (главный мозг)
:9225  — Vision Fallback (MiMo + Ollama)
:8888  — SearXNG (веб-поиск)
:11434 — Ollama (локальные LLM)
```

## Что исправлено (по сравнению с чистой установкой)

- **Голосовой**: STT language auto-detect (русский + английский)
- **Vision**: fallback с MiMo на Ollama при ошибках
- **Watchdog**: автозапуск + мониторинг всех сервисов
- **Proxy**: reasoning xhigh (максимальное рассуждение)
- **Поиск**: локальный SearXNG без captchas

## FAQ

**Q: Скрипт говорит "Python не найден"**
A: Скрипт сам скачает и установит Python. Просто подождите.

**Q: Hermes не запускается**
A: Попробуйте перезагрузить компьютер после установки.

**Q: Нет звука в голосовом**
A: Проверьте настройки микрофона в Windows.

**Q: Картинки не распознаются**
A: Установите Ollama + `ollama pull qwen3.5:9b`

**Q: Как сменить нейросеть?**
A: Отредактируйте `C:\AI\hermes-proxy\config.json`

## Системные требования

- Windows 10/11
- Python 3.13+ (установщик скачает сам)
- Git (установщик скачает сам)
- 4+ GB RAM (для Ollama)
- GPU (опционально, ускоряет Ollama)

## Лицензия

MIT
