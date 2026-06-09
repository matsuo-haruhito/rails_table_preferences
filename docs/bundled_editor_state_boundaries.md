# Bundled editor state boundaries

Use this note when a PR or release-prep check touches the packaged editor search, preset selector fallback, or bundled preset load/save controls.

The goal is to keep browser-visible state, saved settings payloads, and package-entrypoint-only behavior separate. These checks are intentionally narrow: they do not redesign the editor search UI, preset selector, JSON API, or copied controller path.

## Editor search and hidden rows

The package entrypoint can add a column search control above the generated editor rows. Rows that do not match the query are hidden from the current editor view, but they remain part of the editor state.

When this surface is in scope, record:

- whether filtered-out rows stayed in the DOM or were only source-inspected
- whether apply, save, and save-as-new kept hidden rows in the settings payload
- whether row up/down controls moved only the visible filtered subset
- whether move buttons were disabled for hidden rows, first/last visible rows, and async busy state
- whether the copied/base controller path was kept out of scope unless the host app ports the package-entrypoint behavior

Do not describe the visible subset as the full column set. If the smoke uses source-level evidence instead of a browser, say so explicitly.

## First-run preset selector fallback

When the preset collection is empty, the bundled selector may still show a current/default fallback option so the editor can keep a stable load/save target. That fallback is not proof that a saved preset already exists.

When this first-run state is in scope, record:

- whether the selector was loaded from an empty preset collection or from seeded/saved preferences
- whether the visible option represents the current/default editing target rather than an existing saved preset
- whether save and save-as-new still have understandable next actions
- whether helper copy or review notes avoid implying that the fallback option is already persisted
- whether scoped, read-only, duplicate-name, and resolver-priority behavior stayed out of scope

Do not change the JSON API response shape or preset resolver priority just to make the first-run state easier to describe.

## PR note template

```markdown
### Bundled editor state boundary

- Surface checked:
- Rendered evidence:
- Source-only inspection:
- Hidden-row payload / move expectation:
- First-run selector expectation:
- Package-entrypoint-only boundary:
- Out of scope:
```

Escalate to a product or maintainer decision when the PR needs a new no-results behavior, selector disabled state, preset fallback redesign, keyboard reorder contract, or copied-controller parity promise.
