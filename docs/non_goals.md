# Non-goals and deferred directions

Rails Table Preferences is intentionally focused on table display preferences for server-rendered Rails applications.

This document records areas that are intentionally out of scope for now. They may be reconsidered only if real application usage shows strong demand.

## Not planned for the current stage

### Query builder behavior

Rails Table Preferences should not become a generic query builder.

The gem may store filter/sort UI state and convert that state into adapter params, but the host application owns:

- database query execution
- joins and association logic
- authorization
- pagination
- business-specific search behavior

If stronger query integration is needed later, prefer adapter examples or small adapter helpers rather than a full query builder.

### Bundled richer filter widget dependencies

Rails Table Preferences should not bundle date pickers, autocomplete libraries, Select2-style widgets, or form-helper gem dependencies as part of the default filter UI.

The gem can carry neutral filter/editor metadata, saved state, and renderer registry lookup. The host application owns richer widget HTML and behavior, including:

- JavaScript package choice and initialization
- widget-specific validation and visible error feedback
- request timing, remote option loading, and selected-option preload behavior
- field-level authorization and accepted query params
- design-system-specific layout, labels, hints, and responsive polish

When a richer control is needed, use a host-owned partial or a renderer registry mapping to a form helper such as Rails Fields Kit. Keep Rails Table Preferences independent from the concrete widget dependency unless repeated production usage proves that a small, stable adapter is worth adding.

### CSV or Excel generation

Rails Table Preferences should not generate CSV, Excel, or report files by itself.

The gem may provide export payloads such as ordered columns, headers, labels, groups, and export metadata. The host application owns:

- file generation
- formatting values
- authorization for exportable data
- sensitive column handling
- background jobs or streaming

### Complex admin UI

Rails Table Preferences should not become RailsAdmin or a general administration framework.

The gem supports shared, role, and organization scoped presets at the model/API level, but the host application should own any complex admin UI for managing those presets.

A future lightweight example or documentation page may be useful, but the gem should avoid shipping a full preset administration product unless demand is very strong.

### Full Playwright test suite by default

A full Playwright-based browser test stack is not planned for the current stage.

That non-goal is about avoiding a heavy default browser dependency and a broad end-to-end matrix for every host-app behavior. It does not mean browser behavior is ignored. The current quality strategy still relies on:

- manual QA for browser behavior, host app integration, accessibility, and visual/UX issues that are difficult to verify in the automated suite
- the generated demo screen as a lightweight local verification surface for table behavior, preset flows, filters, sorting, fixed columns, column groups, and async recovery
- narrowly scoped smoke checks when they protect an already-documented user-facing flow without turning the gem into a browser-test-heavy package

Prefer keeping browser checks small and tied to documented demo or manual QA scenarios. If UI regressions become costly, add focused smoke coverage or demo verification before introducing a full Playwright suite by default.

### Right-pinned columns and complex sticky layouts

The current fixed/pinned column support is intentionally lightweight.

The gem provides metadata, CSS hooks, and simple left-pinned behavior. The host application owns complex table layout polish, including:

- right-pinned columns
- multiple scroll containers
- grouped headers combined with sticky columns
- design-system-specific shadows and backgrounds
- advanced sticky offset policies

These areas can be reconsidered if real applications show strong demand, but they should not be expanded prematurely.

## Guiding principle

When in doubt, Rails Table Preferences should provide small, composable helpers and stable metadata. Host applications should keep ownership of business behavior, heavy UI, and app-specific layout decisions.