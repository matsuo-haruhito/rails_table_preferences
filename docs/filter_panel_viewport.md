# Filter panel viewport checks

The packaged `rails_table_preferences/controller` entrypoint keeps bundled filter panels anchored near the triggering header while preventing the panel from drifting beyond the viewport right edge.

## Scope

- Applies to the packaged controller entrypoint.
- Keeps the existing open, close, Escape, outside click, scroll close, and resize close behavior.
- Does not redesign the filter panel as a dialog, drawer, Popover API surface, or host-app-specific modal.
- Does not change the copied base controller path. Host apps that copy JavaScript should keep their copied controller aligned manually if they need this viewport clamp.

## Manual review path

Use a representative table with horizontal overflow or a narrow browser width.

1. Scroll to, or render, a rightmost filterable column.
2. Open the column filter panel.
3. Confirm the panel remains within the viewport enough for the operator, value fields, Apply, and Clear controls to be reachable.
4. Confirm the panel still visually belongs to the triggering header.
5. Confirm Escape closes the panel and returns focus to the triggering filter button.
6. Confirm scroll or viewport resize closes the panel rather than leaving a detached floating panel.

## Boundary

The host app still owns surrounding scroll containers, sticky headers, z-index layering against app chrome, and any richer responsive treatment. If a product needs a drawer, modal, or custom placement engine, use the existing copied controller/custom controller path.
