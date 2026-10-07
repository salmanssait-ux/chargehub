# ChargeHub - Codex Project Instructions

## Project
ChargeHub is a Flutter EV charging-station discovery and coverage application.

## Architecture
- Follow the existing Clean Architecture structure.
- Keep presentation, domain, and data layers separated.
- Preserve the existing project structure unless a change is explicitly required.
- Do not introduce a new architectural pattern without discussing it first.
- Keep business logic out of UI widgets.

## State Management
- Use the existing Riverpod setup.
- Reuse existing providers before creating new ones.
- Do not introduce another state-management library.

## Data Sources
- Preserve the existing OSM and Open Charge Map integrations.
- Keep datasource-specific logic inside the data layer.
- Do not move API/network/parsing logic into widgets.
- Reuse existing station models, entities, repositories, and deduplication utilities.

## Flutter / Dart
- Follow existing Dart and Flutter conventions in the project.
- Prefer small, readable widgets.
- Reuse existing widgets before creating duplicates.
- Do not add a dependency when the existing Flutter/Dart APIs can solve the problem.
- Do not change dependency versions unless necessary.
- Do not introduce unnecessary abstractions.

## UI
- Preserve the existing ChargeHub visual language.
- Prefer the existing blue theme and clean EV-navigation style.
- Keep the interface simple and uncluttered.
- Prefer rounded containers, clear spacing, and readable information hierarchy.
- Do not add unnecessary buttons, controls, animations, cards, or decorative UI.
- Do not replace the existing map implementation unless explicitly requested.

## Change Discipline
- Make the smallest change that solves the requested problem.
- Do not refactor unrelated code.
- Do not rename files/classes/functions unless necessary.
- Do not create duplicate implementations.
- Do not rewrite working code just to use a different approach.
- Before creating a new file, check whether an existing file should be extended instead.
- Before creating a new class/provider/widget, search the project for an existing equivalent.

## Dependencies
- Do not add packages automatically.
- If a new package appears necessary, explain why before adding it.
- Prefer existing project dependencies and Flutter SDK functionality.

## Error Handling
- Do not hide errors with empty catch blocks.
- Preserve useful error information.
- Follow the project's existing error/state handling patterns.

## Testing and Verification
After making changes:
1. Run `flutter analyze`.
2. Run relevant tests if they exist.
3. If the change affects the Android build, verify the Android build when practical.
4. Fix errors introduced by your changes.
5. Do not modify unrelated warnings simply to make the output look clean.

## Git Safety
- Do not commit changes unless explicitly asked.
- Do not reset, revert, checkout, clean, or force-push unless explicitly requested.
- Do not delete user changes.
- Do not modify Git history.

## Before Editing
For non-trivial tasks:
1. Inspect the relevant existing files.
2. Understand how the current implementation works.
3. Identify the smallest set of files that need modification.
4. Then implement the change.

## Final Response
After completing a task:
- Summarize what changed.
- List the files changed.
- Mention important design/architecture decisions.
- Report validation performed (`flutter analyze`, tests, build, etc.).
- Mention any remaining issues or assumptions.

## Important
When requirements are ambiguous, prefer preserving existing behavior over inventing new behavior.
Do not make broad improvements that were not requested.
