---
name: flutter-debug
description: Use when debugging Flutter/Dart errors, broken functionality, build failures, runtime issues, or analyzer errors in ChargeHub.
---

# ChargeHub Flutter Debugging

## Rules
- Reproduce or understand the error before changing code.
- Trace the error to its source instead of masking the symptom.
- Prefer the smallest targeted fix.
- Do not rewrite unrelated code.
- Do not suppress analyzer errors without justification.
- Do not add a dependency unless it is genuinely required.

## Workflow
1. Read the complete error.
2. Locate the relevant file and code path.
3. Inspect related providers, models, repositories, and datasources.
4. Identify the root cause.
5. Apply the smallest fix.
6. Run `flutter analyze`.
7. Run relevant tests or build commands when appropriate.
8. Explain the root cause and fix.
