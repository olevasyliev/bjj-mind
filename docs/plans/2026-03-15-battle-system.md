# BJJ Mind — Battle System Implementation Plan
**Date: 2026-03-15**

## Context

Реализация механики боя из Business Logic v5. Боссы и турниры — это пошаговые бои на шкале BJJ позиций.

Текущий код: SessionEngine (вопрос → ответ → следующий вопрос). Бои — полностью новый компонент.

---

## Task 1: Content schema — add `perspective` field

**Что делаем:**
- Добавить `perspective TEXT CHECK (perspective IN ('top', 'bottom'))` в таблицу `questions` в Supabase
- Обновить `Question` модель в Swift: `let perspective: String?`
- Обновить `RemoteQuestion` в `SupabaseService.swift`
- Написать скрипт `scripts/tag_perspectives.py` — проставляет `perspective` для существующих 297 вопросов на основе формулировки + топика (через Claude API)
- Сгенерировать дополнительные вопросы с `perspective: bottom` (защита) — их сейчас мало

**Done when:** Каждый вопрос в Supabase имеет `perspective`. Модели обновлены. Тесты зелёные.

---

## Task 2: BattleScale — data model

**Что делаем:**
Новый файл `BJJMind/Sources/BJJMind/Models/BattleScale.swift`

```swift
enum BJJPosition: String, CaseIterable {
    case submission, backControl, mount, sideControl
    case halfGuard, openGuard, closedGuard
}

struct BattleScale {
    let positions: [BJJPosition]  // ordered left to right, center is midpoint

    // Cycle 1: [sub, mnt, sc, cg, ●, cg, sc, mnt, sub]
    // Cycle 2: [sub, bk, mnt, sc, hg, ●, hg, sc, mnt, bk, sub]
    // etc.

    static func forCycle(_ cycle: Int) -> BattleScale

    func perspective(at markerIndex: Int) -> String  // "top" or "bottom"
    func topic(at markerIndex: Int) -> String        // maps to question topic slug
    func pointsPerTurn(at markerIndex: Int) -> Int   // BJJ scoring
}
```

**Done when:** TDD. BattleScale tests pass: correct positions per cycle, correct perspective, correct point values.

---

## Task 3: OpponentProfile — data model

**Что делаем:**
Новый файл `BJJMind/Sources/BJJMind/Models/OpponentProfile.swift`

```swift
struct OpponentProfile {
    let id: String
    let name: String
    let title: String
    let style: String
    let preFightQuote: String
    let difficulty: Int  // 1–5 stars

    // Attack probabilities
    let weakAttackSuccessRate: Double   // after user correct answer
    let strongAttackSuccessRate: Double // after user wrong answer
    let strongAttackSteps: Int          // 1 or 2 steps back

    // Corner tip (static for MVP, Claude API later)
    let cornerTip: String
}
```

Создать профили для всех соперников финального турнира белого пояса:
Marcus, Diego, Yuki, Andre, Coach Santos.

**Done when:** Все 5 профилей созданы. Тесты на attack probability расчёты.

---

## Task 4: BattleEngine — core logic

**Что делаем:**
Новый файл `BJJMind/Sources/BJJMind/Core/BattleEngine.swift`

```swift
@MainActor
class BattleEngine: ObservableObject {
    enum State {
        case playerTurn(question: Question)
        case showingPlayerResult(correct: Bool)
        case opponentTurn
        case showingOpponentResult(moved: Bool, steps: Int)
        case playerWin(bySubmission: Bool)
        case opponentWin(bySubmission: Bool)
    }

    @Published private(set) var state: State
    @Published private(set) var markerIndex: Int      // position on scale
    @Published private(set) var turnCount: Int
    @Published private(set) var playerScore: Int      // accumulated BJJ points
    @Published private(set) var opponentScore: Int

    let scale: BattleScale
    let opponent: OpponentProfile
    let maxTurns: Int

    func submitAnswer(_ answer: String) async
    private func opponentAttack()
    private func checkWinCondition() -> State?
    private func calculateAdvantage() -> State  // for tied games
}
```

**Done when:** TDD. Tests cover:
- Correct answer moves marker forward
- Wrong answer + opponent strong attack
- Submission win detection (marker at end)
- Points win detection (turn limit reached)
- Advantage calculation (tie → count turns per zone)
- Marker never goes out of bounds

---

## Task 5: BattleView — UI

**Что делаем:**
Новый файл `BJJMind/Sources/BJJMind/Battle/BattleView.swift`

Компоненты:
- `PositionScaleView` — горизонтальная шкала с маркером, анимация движения
- `BattleQuestionView` — вопрос + 3 варианта ответа (не 2, не 4 — всегда 3 в боях)
- `OpponentTurnView` — анимация "соперник атакует" (0.8 сек)
- `CornerView` — экран между боями (Marco + подсказка)
- `BattleResultView` — победа/поражение с деталями

Position scale визуально: каждая позиция — иконка/лейбл, маркер — цветная точка с анимацией sliding.

**Done when:** Полный бой проходится от начала до победного/проигрышного экрана.

---

## Task 6: Tournament bracket — structure + UI

**Что делаем:**
Новый файл `BJJMind/Sources/BJJMind/Models/Tournament.swift`

```swift
struct Tournament {
    let id: String
    let type: TournamentType  // .intermediate, .final
    let fights: [TournamentFight]
    var currentFightIndex: Int
    var status: TournamentStatus  // .inProgress, .won, .lost(atFightIndex:)
}

struct TournamentFight {
    let round: TournamentRound  // .r16, .r8, .qf, .sf, .final
    let opponent: OpponentProfile
    let maxTurns: Int
    var result: FightResult?
}
```

`TournamentBracketView` — визуальная сетка, пользователь видит где он в турнире.
`TournamentDebriefView` — после турнира: схема боёв, паттерн ошибок, ссылки на уроки.

**Done when:** Турнир из 5 боёв проходится полностью. Bracket UI обновляется после каждого боя. Дебриф показывает ошибки.

---

## Task 7: Cycle structure — update content model

**Что делаем:**
Обновить структуру контента под v5:

- `UnitKind` добавить: `.bossf fight`, `.intermediateTournament`, `.finalTournament`
- Убрать `.miniExam`, `.beltTest` (заменены турнирами)
- `Unit` добавить поля: `cycleNumber: Int?`, `isBoss: Bool`
- Обновить SampleData под 4-цикловую структуру белого пояса

**Belt structure в SampleData:**
```
Cycle 1 — Closed Guard (10 lessons + 2 bosses + stripe)
Cycle 2 — Half Guard (10 + review + combo + boss + stripe)
→ Intermediate Tournament (3 fights)
Cycle 3 — Turtle (10 + review + combo + boss + stripe)
Cycle 4 — Open Guard (10 + review + combo + boss + stripe)
→ Final Tournament (5 fights) → Blue Belt
```

**Done when:** HomeView показывает новую структуру. Тесты на cycle progression.

---

## Task 8: Question fetching for battles

**Что делаем:**
Обновить `SupabaseService.fetchQuestionsForSession` для поддержки боёв:

```swift
func fetchQuestionsForBattle(
    position: BJJPosition,
    perspective: String,  // "top" or "bottom"
    beltLevel: String,
    userId: UUID,
    count: Int
) async throws -> [Question]
```

Адаптивная логика остаётся — слабые вопросы приоритизируются.

**Done when:** Battle получает вопросы правильной позиции и перспективы. Тесты.

---

## Порядок реализации

```
Task 1 (контент) → Task 2 (шкала) → Task 3 (соперники) → Task 4 (движок)
    → Task 5 (UI) → Task 6 (турнир) → Task 7 (структура) → Task 8 (фетчинг)
```

Tasks 2 и 3 можно параллельно после Task 1.

---

## Что НЕ делаем сейчас (Phase 5)

- 3D анимации позиций (другой инженер, добавляется позже)
- Claude API для "угла" (статичный текст для MVP)
- P2P реальные соперники (v2.5)
- Брендированные турниры (bizdev)
