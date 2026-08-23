# Hermes FullStack

> **AI-ассистент на голый Windows одной кнопкой.**
> Скачал файл → кликнул → пошёл пить кофе → через 15 минут всё работает.

## Установка на чистый Windows

### Самый простой способ (для всех)

1. Скачайте `INSTALL.bat` с [GitHub Releases](https://github.com/M501/hermes-fullstack/releases)
2. Дважды кликните
3. Согласитесь с установкой Python/Git/Ollama (окно "Контроль учётных записей")
4. Подождите ~15 минут
5. Готово!

Скрипт **сам** скачает и установит:
- Python 3.13 (если нет)
- Git (если нет)
- Hermes Agent
- OpenCode Proxy (бесплатные нейросети)
- Vision Fallback (распознавание картинок)
- SearXNG (локальный поиск)
- Ollama + модель qwen3.5:9b (~6.5 GB)
- Конфигурацию с фиксами
- Лаунчер на рабочий стол

### Через git clone (для тех, кто умеет)

```cmd
git clone https://github.com/M501/hermes-fullstack.git C:\AI\hermes-fullstack
cd C:\AI\hermes-fullstack
powershell -ExecutionPolicy Bypass -File scripts\install-full.ps1
```

## Что устанавливается

| Компонент | Порт | Описание | Размер |
|-----------|------|----------|--------|
| **Hermes Agent** | — | AI-ассистент с Telegram, голосовым, памятью | ~100 MB |
| **OpenCode Proxy** | `:9224` | Бесплатные нейросети (MiMo, DeepSeek, Nemotron) | ~10 MB |
| **Vision Fallback** | `:9225` | Распознавание картинок (MiMo → Ollama) | ~1 MB |
| **SearXNG** | `:8888` | Локальный поиск (DDG, Bing, Wikipedia) | ~50 MB |
| **Ollama** | `:11434` | Локальная нейросеть (vision fallback) | ~500 MB |
| **qwen3.5:9b** | — | Модель для распознавания картинок | ~6.5 GB |

**Итого: ~7 GB места на диске**

## Системные требования

- Windows 10/11 (64-bit)
- Интернет (для скачивания)
- 4+ GB RAM (для Ollama)
- GPU (опционально, ускоряет Ollama)

## После установки

### Запуск
Дважды кликните **"Hermes + MiMo.bat"** на рабочем столе.

### Telegram бот
1. Откройте Telegram, найдите [@BotFather](https://t.me/BotFather)
2. Отправьте `/newbot`
3. Следуйте инструкциям, скопируйте токен
4. Вставьте токен при установке (или отредактируйте `C:\AI\HERMES\.hermes\.env`)

### Голосовой
Нажмите `Ctrl+B` в Hermes → говорите → Hermes распознаёт русский и английский.

## Структура

```
hermes-fullstack/
├── INSTALL.bat                  ← ОДИН ФАЙЛ ДЛЯ ВСЕХ
├── scripts/
│   ├── install-full.ps1         ← Полный PowerShell-установщик
│   ├── setup-searxng.bat        ← Доп. установка SearXNG
│   ├── install-watchdog.ps1     ← Регистрация watchdog
│   └── healthcheck.bat          ← Проверка здоровья
├── launchers/
│   └── Hermes + MiMo.bat       ← Лаунчер (на рабочий стол)
├── config-templates/
│   ├── config.yaml              ← Конфиг Hermes с фиксами
│   └── .env                     ← Шаблон ключей
├── vision-fallback/
│   └── vision_fallback.py       ← MiMo → Ollama fallback
├── watchdog/
│   └── watchdog.ps1             ← Супервизор сервисов
├── webstack-config/
│   └── settings.yml             ← SearXNG конфиг
└── README.md
```

## Порты

```
:9224  — OpenCode Proxy (главный мозг)
:9225  — Vision Fallback (MiMo + Ollama)
:8888  — SearXNG (веб-поиск)
:11434 — Ollama (локальные LLM)
```

## Что исправлено

- **Research First**: перед каждым ответом о фактах — обязательный веб-поиск
- **Голосовой**: STT language auto-detect (русский + английский, не "en")
- **Vision**: основная модель (MiMo) сама распознаёт изображения, отдельный vision не нужен
- **Watchdog**: автозапуск + мониторинг 4 сервисов
- **Proxy**: reasoning xhigh (максимальное рассуждение)
- **Поиск**: локальный SearXNG без captchas

## FAQ

**Q: Скрипт требует "Контроль учётных записей" (UAC)**
A: Это нормально — нужно для установки Python/Git/Ollama. Нажмите "Да".

**Q: Ollama не скачивает модель**
A: Запустите позже: `ollama pull qwen3.5:9b`

**Q: Hermes не запускается**
A: Перезагрузите компьютер после установки.

**Q: Нет звука в голосовом**
A: Проверьте настройки микрофона в Windows.

**Q: Как сменить нейросеть?**
A: Отредактируйте `C:\AI\hermes-proxy\config.json`

**Q: Где логи установки?**
A: `C:\AI\logs\` (python-install.log, git-install.log)

## Лицензия

MIT
