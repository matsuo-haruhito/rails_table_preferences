# Forced-colors manual QA note

Use this companion note when a design or accessibility review needs focused evidence for the default Rails Table Preferences CSS in forced-colors or high-contrast mode.

The bundled CSS intentionally stays lightweight and system-friendly. It uses values such as `currentColor`, `canvas`, and `canvastext` so host applications can keep their own brand and theme decisions. This note is therefore a manual QA checklist, not a promise that the gem owns every final high-contrast theme decision.

## Scope

Check these default affordances on a generated demo screen or a representative host-app table:

- active filter buttons
- sortable header state
- focused resize handles
- open filter panel boundary
- pinned or fixed column background
- focused interactive content inside pinned or fixed cells

Do not use this pass to redesign the active filter cue, introduce a theme system, or change sticky layout policy. If the host app theme makes a state ambiguous, prefer the smallest host-app stylesheet or copied stylesheet adjustment that restores the cue.

## Suggested browser pass

Run the normal quick smoke first, then repeat the focused checks with forced-colors or high-contrast mode enabled.

1. Open the table screen and confirm the editor, table, and at least one filterable column render.
2. Apply a filter and confirm the active filter button is distinguishable from inactive filters without relying on color alone. The button should still expose the active state through `aria-pressed`, `title`, or `aria-label`.
3. Sort a column and confirm the sorted header keeps `aria-sort` plus a visible cue.
4. Move keyboard focus to a resize handle and confirm the focus outline is visible near filter and sort controls.
5. Open a filter panel and confirm the panel boundary remains visible against the table background and surrounding app chrome.
6. Horizontally scroll a table with pinned or fixed columns and confirm the pinned cells keep an opaque background.
7. While horizontally scrolled, tab to links, buttons, inputs, and filter controls near pinned cells and confirm focus outlines are not hidden behind the pinned layer.

## Pass / fail notes

Record evidence in the PR or QA note using this shape:

```markdown
### Forced-colors / high-contrast QA

- Surface checked:
- Browser / mode:
- Active filter cue:
- Sorted header cue:
- Resize handle focus:
- Filter panel boundary:
- Pinned/fixed cell background:
- Focused content near pinned cells:
- Follow-up needed:
```

Use `Follow-up needed` when the final host app theme obscures a cue. Keep that follow-up scoped to CSS or copy near the affected surface unless the product needs a broader visual redesign.

## Host application boundary

Rails Table Preferences provides default hooks and a practical baseline, but the host application owns:

- final color palette and contrast after applying app-specific styles
- custom forced-colors overrides for the host design system
- z-index ordering around surrounding app chrome, sticky headers, dropdowns, or modals
- decisions about stronger active-filter, sort, or pinned-column visual treatments
- browser-capable evidence for the final deployed screen

When a design PR cannot run a browser-capable pass, include this note as the QA handoff and say which checks still need desktop and narrow-width confirmation.
