# BJJ Mind — Figma Design Session Plan

## Context
- Figma MCP подключён (требовал рестарт Claude)
- Дизайн-документ: `2026-03-06-bjj-mind-design.md`
- Прототип (HTML): `bjj-prototype/index.html`
- Визуальный движок: GrappleMap (Babylon.js, public domain)

## Задача
Нарисовать все экраны BJJ Mind в Figma.
Стиль: Duolingo как эталон UX/UI паттернов, стилизованный под BJJ Mind.
Подход: схематически точно, затем полный дизайн.
Я (Claude) = дизайнер с опытом Duolingo и похожих приложений.

## Экраны для дизайна (по приоритету)

### Onboarding (первый запуск)
1. Welcome screen
2. "Твой пояс?" (выбор уровня)
3. "Твоя главная проблема?" (выбор боли)
4. Aha-момент — первый сценарий сразу

### Главные экраны (таббар)
5. Home — Today Card (3 кольца) + Start Session + Marco daily card
6. Train — Belt Path (вертикальная дорожка юнитов)
7. Compete — Tournament Run + Quick Match vs Kat + League Ladder
8. Progress — Belt + stripes + radar chart по тегам
9. Profile — Gi Ghost + Titles + статистика

### Игровые экраны
10. Micro-round Card — 3D сцена + таймер + A/B выбор
11. Feedback Toast — правильно (зелёный) и неправильно (красный)
12. Summary Card — итоги сессии + 2 инсайта
13. Belt Test Gate — экзамен перед страйпом
14. Coach Clip Player — Marco / Old Chen анимашка

### Соревнование
15. Full Match screen — твой ход vs Kat
16. Tournament Run — 5 матчей подряд + ресурсы
17. League Ladder

## Порядок работы
1. Создать Figma файл "BJJ Mind"
2. Настроить Design System: цвета, типографика, компоненты
3. Рисовать экраны в порядке выше
4. После каждого блока — скриншот и проверка

## Design System (предварительно)
- Размер фрейма: 390 x 844 (iPhone 14)
- Тёмная тема (как в прототипе: #0d1117 background)
- Акцент: зелёный (XP, победа) + красный (опасность, ошибка)
- Синий: игрок / Красный: оппонент (из GrappleMap)
- Шрифт: SF Pro (системный iOS) или Inter
- Компоненты: карточки с rounded corners (14-16px), dark cards on dark bg

## Референсы
- Duolingo: Belt Path = их вертикальная дорожка уроков
- Duolingo: Today Card = их streak + XP bar
- Duolingo: Feedback Toast = их зелёный/красный фидбек
- Chess.com: матч экран (пошаговая механика)
- Flo Grappling: стилистика BJJ-контента
