# Demo preview evidence copying

The generated demo screen keeps the hidden fields preview and export payload preview readable as normal page content, then adds demo-only copy controls when the browser exposes the Clipboard API.

Use the copy controls when a PR comment, manual QA sign-off, or host-app issue needs pasted evidence from the generated demo:

- `Copy hidden fields evidence` copies the escaped hidden input markup produced by `table_preferences_hidden_fields(...)`.
- `Copy export payload evidence` copies compact text for the default and `include_hidden: true` export payload rows, including headers, column keys, and export keys.

If the browser does not expose the Clipboard API, the generated demo disables the copy controls and leaves the preview content visible for manual selection. This is a demo-only evidence helper; it does not add production export UI, CSV/Excel generation, or a host-app preset management surface.

For the broader generated demo setup and checklist, see [Demo screen generator](demo.md) and [Manual QA checklist](manual_qa.md).
