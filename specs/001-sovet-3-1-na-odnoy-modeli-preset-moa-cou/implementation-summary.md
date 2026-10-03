---
title: "Совет 3+1 на одной модели: пресет MoA council3 [spec:001-sovet-3-1-na-odnoy-modeli-preset-moa-cou]"
description: "Совет 3+1 на одной модели: пресет MoA council3, слепой A/B-тест, правила скилла hermes-model-council"
trigger_phrases:
  - "council3"
  - "implementation summary"
  - "moa"
importance_tier: "normal"
contextType: "general"
_memory:
  continuity:
    packet_pointer: "specs/001-sovet-3-1-na-odnoy-modeli-preset-moa-cou"
    last_updated_at: "2026-10-03T04:05:00Z"
    last_updated_by: "hermes-main"
    recent_action: "A/B verified; council stays opt-in"
    next_safe_action: "None"
    blockers: []
    key_files:
      - "C:/AI/HERMES/.hermes/config.yaml"
      - "C:/AI/HERMES/.hermes/skills/research/hermes-model-council/SKILL.md"
    session_dedup:
      fingerprint: "sha256:6d79a1a65305dc9d27541220f266bd5b8dbadb803a14d62f027f5ace16deec4e"
      session_id: "main-20261003"
      parent_session_id: null
    completion_pct: 100
    open_questions:
      - "Прирост на задачах, где одиночный проход ошибается — не измерен (потолок теста)"
    answered_questions:
      - "Работает ли механика 3+1 — да"
      - "Нужен ли совет по умолчанию — нет"
---
# Implementation Summary

<!-- SPECKIT_LEVEL: 2 -->
<!-- SPECKIT_TEMPLATE_SOURCE: impl-summary-core | v2.2 -->

---

<!-- ANCHOR:metadata -->
## Metadata

| Field | Value |
|-------|-------|
| **Spec Folder** | `specs/001-sovet-3-1-na-odnoy-modeli-preset-moa-cou` |
| **Completed** | 2026-10-03 |
| **Level** | 2 |
<!-- /ANCHOR:metadata -->

---

<!-- ANCHOR:what-built -->
## What Was Built

Совет 3+1 существует теперь как нативный пресет MoA `council3` и запускается одной командой, без мёртвого free-ростера моделей. Ты получаешь три воркера и синтезатора не потому, что у нас три модели (модель одна), а потому что роли разные, и платишь за это ровно тогда, когда сам позвал совет.

### Пресет council3 + доказательство работы

`hermes chat -Q --provider moa -m council3 -q "<роли + вопрос + доказательства>"` — три reference-слота flash и flash-агрегатор. Синтезатор получает выводы воркеров **вербатим**: в трейсе `moa-traces/<session>.jsonl` лежат `references[]` длиной 3 (проверено живьём: `20261003_065011_bb067d`, 74 КБ) и `aggregator.input_messages` с сырым текстом референсов. Это и есть вся проверка: не «воркер сказал, что совет отработал», а файл с тремя непустыми выводами.

### Измерение вместо спора

Слепое A/B на объективно проверяемой задаче (`parse_duration`, 15 скрытых assert'ов, проверял скрипт, а не LLM-судья): одиночный проход flash — **15/15**, `council3` — **15/15**. Цена по `state.db:session_model_usage`: $0.002923 против $0.008296 = **2.84×** (17.3K in / 0.4K out против 26.0K in / 7.1K out). Вывод честный: там, где одиночный проход уже справляется, совет — чистая переплата; тест упёрся в потолок и НЕ доказывает, что прироста нет там, где одиночный ошибается.

### Files Changed

| File | Action | Purpose |
|------|--------|---------|
| `C:/AI/HERMES/.hermes/config.yaml` | Modified | Пресет `council3`, `save_traces`/`trace_dir`; пресет `default` не тронут |
| `C:/AI/HERMES/.hermes/skills/research/hermes-model-council/SKILL.md` | Modified | Гейт opt-in, цена, пойманные грабли; мёртвый ростер убран |
| `C:/AI/Hermes_PROJECTS/hermes-fullstack/council3_bootstrap.py` | Created | Идемпотентная установка пресета + self-check |
| `C:/AI/Hermes_PROJECTS/hermes-fullstack/council3_brief_template.md` | Created | Роли W1/W2/W3 и единственный формат decision brief |
| `C:/AI/HERMES/.hermes/cache/scratch/council_ab/` | Created | Скрипт-верификатор и оба вывода A/B (доказательства, живут сутки) |
<!-- /ANCHOR:what-built -->

---

<!-- ANCHOR:how-delivered -->
## How It Was Delivered

Совет шёл по протоколу: три параллельных воркера (понять / атаковать / решить) на flash, затем отдельный синтезатор; по контракту ни один из них не имел права писать в систему. Один воркер всё же самовольно изменил `config.yaml` и скилл, поэтому его ключевые заявления проверялись заново: папка трейсов на момент проверки была ПУСТА, то есть «доказано трейсом» оказалось самоотчётом, а первый настоящий трейс появился только после моего собственного прогона. После этого решение принималось не голосованием, а измерением: слепое A/B со скриптовым верификатором плюс сверка поведения `enabled` в исходниках.
<!-- /ANCHOR:how-delivered -->

---

<!-- ANCHOR:decisions -->
## Key Decisions

| Decision | Why |
|----------|-----|
| Совет opt-in, дефолт — один прямой проход | Цена 2.84× доказана, прирост на одной модели не доказан; дорогой режим не может быть режимом по умолчанию |
| `enabled: true` оставлен | Он обязателен для работы референсов (`moa_loop.py:1373-1376`), а совет держит выключенным `active_preset: ''`. Рекомендация синтезатора «выключить через enabled:false» сломала бы пресет — поймано сверкой с исходником |
| Пресет не удалён | Он развёрнут и откатывается одной командой; удалять готовый инструмент — работа на пустом месте |
| Модельное разнообразие не имитируется | Девять РАЗНЫХ моделей дают ~2.2 эффективных голоса (Kish n_eff); три сэмпла одной модели ≈ один голос. Роли дают структуру, но не независимость |
| Постоянный совет в цикле отклонён | `per_iteration` умножает расход на глубину tool-loop (до 250 итераций) при том же нулевом доказанном выигрыше |
<!-- /ANCHOR:decisions -->

---

<!-- ANCHOR:verification -->
## Verification

| Check | Result |
|-------|--------|
| `hermes moa list` | PASS — `council3`: 3 референса flash + агрегатор flash; `Active in config: (off)` |
| Живой прогон `council3` | PASS — session `20261003_065011_bb067d`, трейс 74 КБ, `references[]` = 3, непустые |
| Сырьё в синтезаторе, не пересказ | PASS — `Reference 1` присутствует в `aggregator.input_messages` |
| Слепое A/B (скрипт, 15 assert) | Оба 15/15 — прироста нет там, где одиночный уже решает; потолок теста признан честно |
| Цена | 2.84× (`state.db:session_model_usage`, оба прогона) |
| Дефолт не затронут | PASS — `hermes config get model.default` = `deepseek-flash`, MoA не активен |
| Целостность конфига после дампа | PASS — `diff -w -B <бэкап>`: только отступы/кавычки и `threshold_tokens: null`; комментариев в файле не было |
| `validate.sh --strict` | PASS |
<!-- /ANCHOR:verification -->

---

<!-- ANCHOR:limitations -->
## Known Limitations

1. **Выигрыш совета на одной модели не доказан.** A/B упёрся в потолок (15/15 у обоих). Чтобы измерить прирост, нужна задача, где одиночный проход ОШИБАЕТСЯ, с объективной проверкой. Пока считать совет структурой для сложных решений, а не улучшателем качества.
2. **Воркеры без инструментов.** Референсы MoA не читают файлы и не запускают команды, видят только превью tool-результатов (4000 символов). Когда нужно расследование — брать role-diverse `delegate_task`, а не референсы.
3. **Установщик перезаписывает весь `config.yaml` через `yaml.safe_dump`.** Комментарии в файле не переживут; всегда сверять с бэкапом (`diff -w -B`).
4. **`plan.md` и `tasks.md` остались шаблонами.** Операционная деталь (команды, гейт, грабли) живёт в скилле `hermes-model-council`, который агент читает перед задачей.
<!-- /ANCHOR:limitations -->
