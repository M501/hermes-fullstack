# Research First — Mandatory Rule
#
# This file is loaded as prefill messages at the start of every session.
# It enforces the "Research First" workflow for ALL fact-based questions.
#
# IMPORTANT: This rule is MANDATORY. Every response about facts, events,
# technologies, people, prices, or news MUST go through research first.

## Research First (ОБЯЗАТЕЛЬНО)

**Перед ответом о фактах, событиях, технологиях, людях, ценах, новостях —
ЛЮБОМ вопросе где важна точность — СНАЧАЛА research, ПОТОМ ответ.**

### Цепочка

1. Вопрос требует fact-checking / актуальных данных? → **обязательно** research
2. Выполни через webstack CLI:
   ```
   cd C:\AI\ecc-final\webstack
   .venv/Scripts/python -m webstack research "запрос" --read 5 --search-max 10
   ```
   Или по шагам: search → read → evidence
3. Синтезируй ответ с citations (URL + verdict high/medium/low)
4. НЕ отвечай из памяти когда research показал что-то другое

### Multi-hop

Сложные вопросы → разбивай на под-вопросы → research по каждому.

### STOP

- STOP: все факты покрыты + нет противоречий
- CONTINUE: 1 домен, низкое качество, противоречия в источниках
- HARD STOP: бюджет исчерпан. Честно скажи что не нашёл.

---

## Vision (распознавание изображений)

**Основная модель (MiMo V2.5 Free через OpenCode Proxy :9224) сама распознаёт
изображения.** Отдельно вызывать vision_analyze НЕ нужно — модель анализирует
любые картинки, скриншоты, документы которые ей отправляют.

Вспомогательный vision (:9225, MiMo → Ollama fallback) используется ТОЛЬКО
когда основной прокси :9224 недоступен. Это автоматический fallback, не
ручной инструмент.

### Порты для справки
- :9224 — OpenCode Proxy (главный мозг, текст + vision + reasoning)
- :9225 — Vision Fallback (только если :9224 упал)
- :8888 — SearXNG (локальный поиск)
- :11434 — Ollama (локальные модели)
