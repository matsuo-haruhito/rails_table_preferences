## Summary

-

## Related Issues

Closes #

## Changes

-

## Verification

- Automated checks, specs, or docs-only review:
- Manual QA applicability:
- UI / visual evidence:

## Focused Manual QA

Use `docs/manual_qa_pr_smoke_matrix.md` when this PR changes browser-visible behavior, generated demo output, helper-rendered markup, JavaScript interactions, or release-facing QA guidance.

- PR category:
- Screen or artifact checked:
- Viewports or states checked:
- Evidence:
- Skipped full-checklist areas and reason:
- Follow-up needed:

For docs-only or spec-only changes, it is fine to write `not applicable` when the changed text does not claim a rendered UI state.

## UI / Visual Evidence

Use this section only when the PR changes visible UI, layout, copy that affects a control, or a visual reference. Docs-only API wording and non-visual code changes can mark this as not applicable.

For static visual docs or docs image changes, use the `Static visual docs or docs image` category in `docs/manual_qa_pr_smoke_matrix.md` to record whether source diff, rendered visual confirmation, or a browser-capable handoff was used. This does not replace browser evidence for runtime UI, layout, or control-copy changes.

- Screenshot or visual evidence attached, or not applicable because:
- Representative surface checked:
  - Editor / preset actions
  - Filter panel / sortable or resizable headers
  - Resource table / fixed columns / grouped headers
  - Other:
- Viewport/state checked, kept to the smallest useful set:
  - Default desktop or host-app list width
  - One narrow width or narrow container when layout can wrap
  - One long-label, long-value, or empty/loading/error state when relevant
  - One forced-colors or high contrast state when color, focus, filter, sort, resize, panel, or pinned/fixed column cues are touched
- Narrow editor-row evidence, when editor layout or dense labels are touched:
  - 320px / 375px / 390px-equivalent width, or narrow container used:
  - Long Japanese or unbroken label checked:
  - Drag handle, visible checkbox, order/width/truncate inputs remained reachable, or human handoff because:
- Forced-colors / high contrast evidence, when relevant:
  - Mode or environment used:
  - States checked: active filter / sorted header / focused resize handle / open filter panel / pinned or fixed column / other:
  - States skipped and why:
- If browser capture was unavailable, substitute evidence is listed in the PR body or comment, such as focused specs, source-level DOM assertions, static visual reference review, or human reviewer handoff.

## Existing Behavior / Compatibility

- Public API / JSON API / DB schema / authorization changes:
- Host-app responsibility boundaries:

## Risk

- Risk level:
- Rollback notes:

## Notes

-
