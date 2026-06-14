# TypeScript settings snapshot declarations

Rails Table Preferences packages TypeScript helper types for the settings snapshots exposed through package-entrypoint lifecycle events.

Host apps can import the helpers from the package root:

```ts
import type {
  RailsTablePreferencesColumnSnapshot,
  RailsTablePreferencesFilterSnapshot,
  RailsTablePreferencesSettingsSnapshot,
  RailsTablePreferencesSortSnapshot
} from "rails_table_preferences"
```

The snapshot helpers describe the stable shape that package-entrypoint event consumers can use when inspecting `event.detail.settings`:

- `RailsTablePreferencesSettingsSnapshot` groups the optional `columns`, `filters`, and `sorts` collections while allowing additional server-provided keys.
- `RailsTablePreferencesColumnSnapshot` covers common column metadata exported from the Rails column definitions, including keys, labels, visibility, ordering, width, truncation, overflow, grouping, filtering, and sorting hints.
- `RailsTablePreferencesFilterSnapshot` covers representative filter metadata and intentionally keeps filter values open-ended because host apps may provide scalar values, arrays, ranges, or option payloads.
- `RailsTablePreferencesSortSnapshot` describes persisted sort entries by key and direction while allowing additional sort metadata.

These declarations are compile-time helpers only. They do not validate runtime payloads, replace Rails-side column or filter definitions, or guarantee that every host application uses every optional property. Treat unknown keys as extension data supplied by the server or host app.

The helper types belong to the package entrypoint contract. Host apps that register a copied or replacement controller can still import the types for local convenience, but doing so does not prove that the copied controller dispatches the package-entrypoint lifecycle events unless that behavior has been ported locally.
