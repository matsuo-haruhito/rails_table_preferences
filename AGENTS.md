# Rails Table Preferences Agent Guide

## Mission

Rails Table Preferences is a Rails engine/gem for Rails applications that need to save and restore table display preferences without taking over the host application's query execution, authorization, export generation, or admin framework.

Keep the project focused on business-application table UX: column visibility, order, width, overflow, fixed columns, grouped columns, filter/sort UI state, presets, and export payload helpers.

## Product summary

The repository currently provides:

- Rails helpers for defining columns and rendering the editor/table surface
- controller helpers and adapters for existing params/search flows
- a bundled Stimulus controller and lightweight JSON API
- generators for install, JavaScript, stylesheets, views, and optional demo setup
- focused docs under `docs/` for integration, QA, release, and troubleshooting

## Source of truth

When deciding what is correct, use this order:

1. current code and specs
2. `README.md` and `docs/index.md`, then the focused guides under `docs/`
3. `CHANGELOG.md` for release narrative
4. `Product Profile.md` for maintainer-facing context

If docs and code disagree, prefer the current code/specs and update docs to match. Do not invent behavior that the repository does not implement.

## Responsibility boundary

Rails Table Preferences owns:

- table display preference UI and persistence
- column visibility, order, width, truncation/overflow, pinned metadata, and group metadata
- owner/shared/role/organization preset behavior already implemented in the codebase
- saved filter/sort UI state and adapter params
- export payload helpers derived from saved preferences
- baseline accessibility hooks for generated controls

Host applications still own:

- search/query execution
- authorization and tenant/business rules
- grouped header markup and scroll-container polish
- CSV/Excel/report file generation
- full admin UI for shared, role, or organization presets
- final visual design and application-specific UX

## Change guardrails

- Do not turn the gem into a query builder, export generator, authorization system, or admin framework.
- Preserve the copy-based customization paths for ERB, CSS, JavaScript, locales, and generators unless an issue explicitly changes them.
- When documenting integrations, make the host-app responsibility boundary explicit instead of implying the gem handles everything.
- Keep `README.md` and `docs/index.md` aligned enough that readers can reliably discover the same focused guides.
- Keep maintainer docs factual and derived from current code/docs rather than roadmap speculation.

## Verification reminders

Before describing a behavior as supported, confirm it in the current code, specs, or existing docs.

For repository maintenance changes, check at least these surfaces when relevant:

- `README.md`
- `docs/index.md`
- the focused guide being updated
- `CHANGELOG.md`
- release/package/manual QA docs when the workflow changes
