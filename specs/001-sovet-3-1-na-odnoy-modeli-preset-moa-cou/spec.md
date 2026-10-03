---
title: "Совет 3+1 на одной модели: пресет MoA council3 [spec:001-sovet-3-1-na-odnoy-modeli-preset-moa-cou]"
description: "Совет 3+1 на одной модели: пресет MoA council3, слепой A/B-тест, правила скилла hermes-model-council"
trigger_phrases:
  - "council"
  - "council3"
  - "moa"
  - "совет"
importance_tier: "normal"
contextType: "general"
_memory:
  continuity:
    packet_pointer: "specs/001-sovet-3-1-na-odnoy-modeli-preset-moa-cou"
    last_updated_at: "2026-10-03T04:05:00Z"
    last_updated_by: "hermes-main"
    recent_action: "Spec filled after council + A/B verification"
    next_safe_action: "None pending; council stays opt-in"
    blockers: []
    key_files:
      - "C:/AI/HERMES/.hermes/config.yaml"
      - "C:/AI/HERMES/.hermes/skills/research/hermes-model-council/SKILL.md"
      - "C:/AI/Hermes_PROJECTS/hermes-fullstack/council3_bootstrap.py"
    session_dedup:
      fingerprint: "sha256:6d79a1a65305dc9d27541220f266bd5b8dbadb803a14d62f027f5ace16deec4e"
      session_id: "main-20261003"
      parent_session_id: null
    completion_pct: 100
    open_questions:
      - "Даёт ли council3 прирост на задачах, где одиночный проход ОШИБАЕТСЯ (не проверено; A/B упёрся в потолок 15/15 у обоих)"
    answered_questions:
      - "Работает ли механика 3+1 на одной модели — да, проверено трейсом"
      - "Нужен ли совет по умолчанию — нет, дефолт один прямой проход"
---

# Feature Specification: Совет 3+1 на одной модели (пресет MoA council3)

<!-- SPECKIT_LEVEL: 2 -->
<!-- SPECKIT_TEMPLATE_SOURCE: spec-core | v2.2 -->

---

<!-- ANCHOR:metadata -->
## 1. METADATA

| Field | Value |
|-------|-------|
| **Level** | 2 |
| **Priority** | P1 |
| **Status** | Complete |
| **Created** | 2026-10-03 |
| **Branch** | `001-sovet-3-1-na-odnoy-modeli-preset-moa-cou` |
<!-- /ANCHOR:metadata -->

---

<!-- ANCHOR:problem -->
## 2. PROBLEM & PURPOSE

### Problem Statement
Нужен «совет» (3 воркера + синтезатор) для сложных задач, но прошлые попытки строились на мёртвой инфраструктуре (free-ростер моделей, прокси :9224). После перехода на единственную модель `deepseek-flash` было неясно, существует ли рабочий совет вообще, чем он платится и когда его запускать; скилл `hermes-model-council` описывал умерший ростер.

### Purpose
Дать один работающий, измеримый и выключенный по умолчанию совет 3+1 на нативном MoA: точная команда запуска, доказательство работы, измеренная цена и правило «когда запускать» (opt-in).
<!-- /ANCHOR:problem -->

---

<!-- ANCHOR:scope -->
## 3. SCOPE

### In Scope
- Пресет MoA `council3` = 3 reference-слота `deepseek:deepseek-flash` + агрегатор `deepseek:deepseek-flash`.
- Трейсы MoA (`moa.save_traces` + `moa.trace_dir`) как единственное доказательство, что воркеры реально отработали.
- Идемпотентный установщик пресета + шаблон decision brief.
- Переписанные правила скилла: opt-in, роль-диверсити вместо модельной, цена, откат.

### Out of Scope
- Постоянный совет в основном цикле (`fanout: per_iteration`) — на одной модели это ×глубину tool-loop без доказанного выигрыша.
- Модельное разнообразие — моделей больше нет (`v4-pro` запрещён, free-ростер мёртв).
- Кроны и любые фоновые авто-запуски совета — только по ручной команде.

### Files to Change

| File Path | Change Type | Description |
|-----------|-------------|-------------|
| `C:/AI/HERMES/.hermes/config.yaml` | Modify | `moa.presets.council3` + `save_traces`/`trace_dir`; бэкап `config.yaml.bak-council3plus1-20261003_064155` |
| `C:/AI/HERMES/.hermes/skills/research/hermes-model-council/SKILL.md` | Modify | Правила под одно-модельный стек, гейт opt-in, пойманные грабли |
| `C:/AI/Hermes_PROJECTS/hermes-fullstack/council3_bootstrap.py` | Create | Идемпотентная установка/проверка пресета |
| `C:/AI/Hermes_PROJECTS/hermes-fullstack/council3_brief_template.md` | Create | Роли W1/W2/W3 + формат decision brief |
<!-- /ANCHOR:scope -->

---

<!-- ANCHOR:requirements -->
## 4. REQUIREMENTS

### P0 - Blockers (MUST complete)

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| REQ-001 | Совет запускается одной неинтерактивной командой | `hermes chat -Q --provider moa -m council3 -q "..."` → exit 0 и session_id |
| REQ-002 | Три воркера реально работают, синтезатор видит их СЫРЬЁ | В `moa-traces/<session>.jsonl`: `references[]` длиной 3, каждый `output` непустой; в `aggregator.input_messages` — текст референсов вербатим (`Reference 1`) |
| REQ-003 | Цена измерена фактом, а не оценкой | Строки `state.db:session_model_usage` по обоим прогонам, отношение зафиксировано |

### P1 - Required (complete OR user-approved deferral)

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| REQ-004 | Дефолт остаётся «один прямой проход» | `moa.active_preset: ''`; обычная сессия = `deepseek-flash`, без MoA-вызовов |
| REQ-005 | Откат в одну команду | `hermes moa delete council3` либо `cp config.yaml.bak-council3plus1-20261003_064155 config.yaml` |
| REQ-006 | Скилл не содержит мёртвых инструкций | Нет указаний звать :9224 / free-ростер / `.opencode`-совет как актуальные |
<!-- /ANCHOR:requirements -->

---

<!-- ANCHOR:success-criteria -->
## 5. SUCCESS CRITERIA

- **SC-001**: Живой прогон `council3` оставляет трейс ровно с 3 референсами и непустым выводом (проверено 2026-10-03, `20261003_065011_bb067d`).
- **SC-002**: Отношение цены совет/одиночный проход измерено на одной задаче и записано (2.84×) вместе с честной оговоркой о потолке теста.
- **SC-003**: Ни одна часть совета не запускается сама: `hermes moa list` печатает «Active in config: (off)».
<!-- /ANCHOR:success-criteria -->

---

<!-- ANCHOR:risks -->
## 6. RISKS & DEPENDENCIES

| Type | Item | Impact | Mitigation |
|------|------|--------|------------|
| Risk | Совет принят за «независимую проверку» | High | Правило: все слоты — одна модель, ошибки коррелированы; выигрыш не доказан, заявлено прямо |
| Risk | Ошибочная «оптимизация» `enabled: false` | High | Зафиксировано: `enabled:true` обязателен, совет выключает `active_preset:''` (`moa_loop.py:1373-1376`) |
| Risk | Установщик перезаписывает весь `config.yaml` дампом | Med | Бэкап обязателен, проверка `diff -w -B`, грабли записаны в скилл |
| Dependency | API DeepSeek (единственный провайдер) | Med | При недоступности — обычный одиночный вызов, совет помечается skipped |
<!-- /ANCHOR:risks -->

---

<!-- ANCHOR:questions -->

---

<!-- ANCHOR:nfr -->
## L2: NON-FUNCTIONAL REQUIREMENTS

### Performance
- **NFR-P01**: Дополнительная цена совета ≤ 3× одиночного прохода (измерено 2.84×).
- **NFR-P02**: `fanout: user_turn` — референсы один раз за ход, дальше cache-hit.

### Security
- **NFR-S01**: Трейсы содержат сырой разговор — секретов в них не хранить, `trace_dir` локальный.
- **NFR-S02**: `privacy_filter: ""` — референсы идут к агрегатору без редактирования; менять только осознанно.

### Reliability
- **NFR-R01**: Падение одного референса не рушит ход (`degraded_reference_policy: loud`).
- **NFR-R02**: Откат конфига одной командой из бэкапа.
<!-- /ANCHOR:nfr -->

---

<!-- ANCHOR:edge-cases -->
## L2: EDGE CASES

### Data Boundaries
- Битый/пустой слот пресета: `_clean_slot` его отбрасывает — фактический состав смотреть через `hermes moa list`.
- Длинные tool-результаты: референсы видят только превью (4000 символов) — синтезатор обязан опираться на факты, а не на пересказ воркеров.

### Error Scenarios
- Недоступность провайдера: ход идёт через агрегатора, референсы помечаются как failed (loud).
- Трейса нет: значит `save_traces` выключен или прогон был не MoA — считать совет несостоявшимся.

### State Transitions
- Прерывание прогона: записи трейса может не быть — трактовать как «не доказано».
- Неполный вывод: перезапустить ту же команду, сравнить трейсы.
<!-- /ANCHOR:edge-cases -->

---

<!-- ANCHOR:complexity -->
## L2: COMPLEXITY ASSESSMENT

| Dimension | Score | Notes |
|-----------|-------|-------|
| Scope | 8/25 | 4 файла: конфиг, скилл, 2 артефакта |
| Risk | 6/25 | Обратимо: бэкап конфига, `hermes moa delete`, правка скилла |
| Research | 14/20 | Разбор исходников MoA, доки, слепой A/B, разбор расхождений воркеров |
| **Total** | **28/70** | **Level 2** |
<!-- /ANCHOR:complexity -->

---

## 10. OPEN QUESTIONS

- Даёт ли `council3` прирост на задачах, где одиночный проход ОШИБАЕТСЯ? A/B упёрся в потолок (15/15 у обоих), поэтому вопрос открыт и намеренно не закрыт догадкой.
<!-- /ANCHOR:questions -->
