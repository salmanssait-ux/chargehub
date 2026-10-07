---
name: architecture
description: Use when adding or changing repositories, datasources, models, entities, providers, business logic, or other architectural code in ChargeHub.
---

# ChargeHub Architecture

## Existing Architecture
Preserve the project's existing Clean Architecture organization.

Typical responsibilities:
- Presentation: pages, widgets, UI state
- Domain: entities and business-level abstractions
- Data: models, datasources, repository implementations, parsing, external APIs
- Providers: Riverpod dependency/state wiring

## Rules
- Keep external API and parsing logic in the data layer.
- Keep business rules out of widgets.
- Keep domain entities independent of API-specific models.
- Prefer existing repository interfaces and implementations.
- Prefer existing providers before creating new ones.
- Do not bypass repositories from presentation code.
- Do not put HTTP/API calls directly inside widgets.
- Do not duplicate station models or repository logic.
- Preserve OSM/OCM datasource boundaries.
- Keep deduplication and data normalization in the appropriate data layer utilities.

## Before Adding Code
Search for:
- existing entity
- existing model
- existing repository
- existing datasource
- existing provider
- existing utility

Extend an existing implementation when appropriate instead of creating a parallel implementation.
