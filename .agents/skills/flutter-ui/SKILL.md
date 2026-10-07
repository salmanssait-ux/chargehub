---
name: flutter-ui
description: Use when modifying ChargeHub Flutter UI, screens, widgets, layouts, themes, map UI, station cards, filters, or navigation.
---

# ChargeHub Flutter UI

## Rules
- Inspect the existing UI before changing it.
- Reuse existing widgets and theme values.
- Keep the UI clean and minimal.
- Prefer small focused widgets.
- Avoid unnecessary nesting.
- Avoid duplicate widgets that perform the same role.
- Preserve existing navigation and state behavior unless the task requires changing it.
- Do not add visual controls that were not requested.
- Keep map UI visually simple and avoid unnecessary provider/map controls.

## Workflow
1. Find the relevant page/widget.
2. Inspect related widgets, providers, and theme definitions.
3. Make the smallest required change.
4. Check for layout issues.
5. Run `flutter analyze`.
