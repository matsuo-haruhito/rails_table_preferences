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

A lightweight browser smoke test may be considered later if manual verification becomes costly or UI regressions appear. The initial release should not be blocked by a heavy browser test dependency.

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
