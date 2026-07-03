# Demo support section smoke boundary

Use this note when a PR or release-prep check touches the generated demo support sections or the visual overview images that point at them.

The goal is to keep four evidence types separate:

- Source inspection confirms docs, generator templates, captions, and button labels still describe the same support sections.
- Rendered demo evidence confirms the copied demo screen actually shows the `Demo state reset`, `Async failure check`, and preview copy controls without overlap, clipping, or misleading grouping.
- Browser-capable handoff records the exact desktop or narrow viewport check that still needs a human/browser review when this environment cannot render the demo.
- Copy fallback evidence records whether preview text stayed readable and manually selectable when Clipboard API support was missing or a copy attempt failed.

## Preview copy controls

Check this section when the PR mentions hidden fields preview, export payload preview, copy controls, Clipboard API fallback, or manual evidence collection.

Record:

- whether the hidden fields preview and export payload preview were rendered or only source-inspected
- whether each copy control still points at the matching preview target id
- whether the copy status region remains a polite status message near the matching control
- whether disabled-copy and failed-copy states tell the reviewer to select the visible preview text manually
- whether manual selection fallback was browser-checked or handed off

Do not claim Clipboard behavior was verified unless a browser-capable check actually exercised the disabled, success, or failed-copy path. Source inspection can confirm the fallback copy, target ids, and status wiring, but it does not prove the preview text is reachable or selectable in the rendered browser.

## Demo state reset

Check this section when the PR mentions scoped preset recovery, owner-scoped cleanup, role / organization precedence, or reset support copy.

Record:

- whether the `Demo state reset` section was rendered or only source-inspected
- whether the `Reset demo verification state` button is visible and clearly demo-only
- whether the section keeps production preset management, authorization, and cleanup policy outside the gem-owned UI promise
- whether the seeded shared / role / organization baseline remains the expected post-reset comparison target

Do not treat source inspection as proof that the button is readable or reachable in the browser.

## Async failure check

Check this section when the PR mentions preset request failure recovery, status-region copy, disabled controls, or one-shot failure support.

Record:

- whether the `Async failure check` section was rendered or only source-inspected
- whether the `Fail next preset request once` button is visible and reads as a one-shot demo helper
- whether save, load, save-as-new, and delete recovery are described as representative preset actions rather than a production failure framework
- whether controls recovery after the failed request was browser-checked or handed off

Do not claim request recovery was verified unless a browser-capable check actually exercised the one-shot failure flow.

## Visual overview images

When `docs/visual_overview.md`, `docs/images/visual-overview-editor-and-table.svg`, or `docs/images/visual-overview-filter-and-pinned-columns.svg` changes, record whether the evidence is rendered visual confirmation or source-only inspection.

Package verification only proves the required SVG files ship in the gem. It does not prove the rendered image still matches its caption, the generated demo posture, or the support sections referenced from the overview.

## PR note template

```markdown
### Demo / visual evidence boundary

- Artifacts checked:
- Source-of-truth docs consulted:
- Rendered evidence:
- Source-only inspection:
- Browser-capable handoff:
- Copy fallback evidence:
- Out of scope:
```

Keep runtime behavior, production preset-management UI, generator defaults, and screenshot automation out of this smoke unless the source Issue explicitly asks for them.
