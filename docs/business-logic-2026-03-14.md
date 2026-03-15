# BJJ Mind — Business Logic Snapshot
**Date: 2026-03-14**

> Что реально работает в приложении сегодня. Отделено от spec/roadmap.

---

## 1. Onboarding

Пользователь проходит 7 экранов, данные сохраняются в Supabase и UserDefaults.

| Шаг | Экран | Что собирает |
|-----|-------|-------------|
| 1 | Welcome | — |
| 2 | Belt Select | `selectedBelt` (white / blue / purple / brown / black) |
| 3 | Skill Assessment | `skillLevel` (beginner / intermediate / advanced) — 2 вопроса |
| 4 | Struggles | `struggles[]` — массив строк (проблемные зоны) |
| 5 | Club Info | `clubInfo` (страна, город, клуб) — опционально, можно пропустить |
| 6 | Aha Moment | Pitch приложения, Gi Ghost |
| 7 | Kat Intro | Kat персонализировано обращается по поясу |

После шага 7 вызывается `completeOnboarding` — создаётся профиль пользователя в Supabase, `AppState.isOnboardingComplete = true`.

---

## 2. Структура учебного контента

### Юниты (ноды на карте)

31 нода в текущем каталоге. Типы:

| Тип (`UnitKind`) | Описание | Кол-во |
|-----------------|----------|--------|
| `.lesson` | Обычный урок по теме | ~20 |
| `.characterMoment` | Монолог персонажа (Marco / Old Chen / Rex / Gi Ghost) — не вопросы | 4 |
| `.mixedReview` | Повторение — вопросы из нескольких тем | 3 |
| `.miniExam` | Мини-экзамен по пройденному блоку | 3 |
| `.beltTest` | Итоговый тест пояса | 1 |

### Темы уроков (topic slugs)

`closed_guard` · `guard_passing` · `side_control` · `mount` · `back_control` · `submissions` · `escapes` · `sweeps` · `half_guard` · `leg_locks`

### Прогрессия

Ноды открываются последовательно. Пользователь видит путь как визуальную карту. Завершённая нода открывает следующую.

---

## 3. Сессия

### Запуск

При нажатии на юнит `SessionView` запускает async-загрузку вопросов:

1. Если у юнита есть `topic` и пользователь залогинен → фетчим из Supabase адаптивно
2. Иначе (оффлайн / нет топика / новый пользователь) → берём вопросы из `SampleData` (локально)

### SessionEngine — стейт машина

```
answering → showingFeedback → answering (следующий вопрос)
                           → completed (все вопросы)
                           → gameOver (закончились жизни)
```

### Жизни (Hearts)

- 5 жизней на сессию
- Неверный ответ = -1 жизнь
- 0 жизней → gameOver, сессия завершается

### Форматы вопросов (реализованы)

| Формат | Описание |
|--------|----------|
| `mcq2` | 2 варианта ответа |
| `mcq4` | 4 варианта ответа |
| `trueFalse` | True / False |
| `fillBlank` | Вписать слово из банка слов |

### Конец сессии

- Показывается `SummaryView` с accuracy, hearts left, streak
- XP начислен (отображается, но не влияет на прогрессию — см. ниже)
- Stats по каждому вопросу записываются в Supabase fire-and-forget
- При gameOver — stats тоже записываются (вопросы, на которых споткнулся, попадут в слабые)

---

## 4. Адаптивный банк вопросов

### База

**297 вопросов** в Supabase (`questions` таблица):
- 80 seed-вопросов (написаны вручную через `migrate_db.py`)
- 197 сгенерированы Claude API (`claude-haiku-4-5-20251001`) по 10 темам

Каждый вопрос имеет: `topic`, `belt_level`, `difficulty` (1–3), `format`, `correct_answer`, `explanation`.

### Алгоритм выбора (AdaptiveQuestionSelector)

Вопросы для сессии сортируются в 3 группы, берутся первые 8:

1. **Никогда не видел** (`times_seen == 0`) — приоритет
2. **Слабые** (`times_wrong >= 2`) — второй приоритет
3. **Остальные** — в конце

Внутри каждой группы — по возрастанию сложности (`difficulty asc`).

### Статистика ошибок (user_question_stats)

После каждой сессии вызывается Supabase RPC `increment_question_stats`:

```sql
-- Атомарно инкрементирует, не перезаписывает
times_seen = times_seen + 1
times_wrong = times_wrong + (1 if wrong else 0)
```

RLS политики: каждый юзер видит только свою статистику.

---

## 5. Belt Test

- Открывается только после завершения всех предыдущих юнитов
- Вопросы из всех тем пояса
- Правила строже: нет подсказок после ошибки (только правильный ответ)
- Проходной порог: accuracy ≥ 80%
- При провале: 24-часовой cooldown перед повтором
- При прохождении: пояс обновляется в профиле

---

## 6. Персонажи

| Персонаж | Где появляется |
|----------|---------------|
| **Gi Ghost** | AhaMoment, feedback-анимации |
| **Marco** | SkillAssessment, CharacterMoment ноды (Coach moments) |
| **Kat** | KatIntro (онбординг), Compete tab (не реализован) |
| **Old Chen** | CharacterMoment ноды |
| **Rex** | CharacterMoment ноды |

---

## 7. Локализация

Поддерживается EN / ES. Архитектура:
- `LanguageManager` — синглтон, переключает bundle в runtime
- `L10n` enum — типизированные строки через `LanguageManager.bundle`
- `SampleData.swift` + `SampleData_ES.swift` — вопросы на двух языках
- `Localizable.strings` (en + es)

Переключение языка — в профиле, без перезапуска приложения.

---

## 8. Supabase — что синхронизируется

| Данные | Таблица | Когда |
|--------|---------|-------|
| Профиль пользователя (belt, skillLevel, struggles, clubInfo) | `user_profiles` | После онбординга + обновление |
| Прогресс по юнитам (completed, locked/unlocked) | `unit_progress` | После завершения юнита |
| Результат сессии (accuracy, xp, hearts) | `session_results` | После каждой сессии |
| Статистика по вопросам (times_seen, times_wrong) | `user_question_stats` | После каждой сессии (RPC) |
| Каталог юнитов + вопросов | `units`, `questions` | При запуске (fetchCatalog) |

Если Supabase недоступен — приложение работает с локальными данными (SampleData), синхронизирует при следующем запуске.

---

## 9. Что отображается, но не влияет на механику (заглушки)

| Элемент | Статус |
|---------|--------|
| **XP** | Считается и показывается, но не связан с прогрессией (stripes, belt test unlock) |
| **Streak** | Показывается в Summary, но не сохраняется между сессиями |
| **Compete tab** | Экран "Coming Soon" |
| **Progress tab** | Экран "Coming Soon" |
| **Tag mastery** | Не реализован |

---

## 10. Версия и тесты

- **Версия:** 1.1.1 (build 4)
- **Тестов:** 110, все зелёные
- **Стек тестов:** XCTest, TDD (тесты пишутся до кода)
- **Деплой:** GitHub `olevasyliev/bjj-mind`, ветка `main`
