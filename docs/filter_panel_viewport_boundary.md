# Filter panel viewport boundary

The packaged controller keeps the bundled filter panel lightweight and body-mounted. It positions the panel below the triggering header cell, keeps the existing horizontal viewport clamp, and constrains the panel height to the remaining viewport space so value fields and action controls can be reached with internal scrolling near the bottom of a short viewport.

## Package-entrypoint behavior

- The panel stays anchored below the header cell; it does not flip above the header.
- The panel keeps the existing `calc(100vw - 16px)` horizontal limit.
- The panel receives a viewport-based `max-height` and `overflow-y: auto` while open.
- Escape, outside click, scroll, and viewport resize keep the existing close behavior.
- The bundled controller does not add a popover library, focus trap, modal dialog, virtualized options, or remote option loading.

Host applications that need a full popover placement policy, modal focus management, sticky-header-specific positioning, or product-specific option widgets should use a copied or replacement controller.

## Browser-capable QA

Use a small viewport or a table header near the bottom of the viewport.

- Open a filter panel and confirm the value fields, Apply, and Clear controls can be reached by scrolling inside the panel.
- Confirm the panel still stays within the horizontal viewport margin.
- Press Escape and confirm focus returns to the triggering filter button.
- Click outside the panel and confirm it closes.
- Scroll or resize the viewport and confirm the body-mounted panel closes instead of drifting away from the header.

This note is a manual QA aid for package-entrypoint behavior. It does not change filter semantics, saved settings shape, adapter params, query execution, API, database state, or authorization.
