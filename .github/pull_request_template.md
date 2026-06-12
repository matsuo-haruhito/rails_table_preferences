## Summary

-

## Related Issues

Choose the relationship intentionally and remove unused lines.

- Closes #... when this PR fully completes the issue on merge.
- Refs #... when this PR is partial, stacked, exploratory, or needs human review before the issue should close.
- Supersedes #... when this PR replaces an older PR or proposal; name the replaced PR in Notes or the focused QA section.

## Changes

-

## Verification

- Automated checks, specs, or docs-only review:
- Release/package evidence or package verification summary:
- Manual QA applicability and selected matrix category:
- UI / visual evidence status, or why not applicable:

## Current Review State

Record the current GitHub state used for review or merge decisions. Do not rely on older PR-body CI notes without refreshing these fields. Keep CI/check status separate from UI or visual approval; a green workflow does not prove a rendered browser state.

- Head SHA or compare head:
- Workflow run or checks summary:
- Compare freshness, for example `behind_by: 0`, stacked base, or replacement PR:
- Mergeability, for example `mergeable:true`, conflicts, or unknown:

## Focused Manual QA

Use `docs/manual_qa_pr_smoke_matrix.md` as the source-of-truth category and evidence-boundary guide when this PR changes browser-visible behavior, generated demo output, helper-rendered markup, JavaScript interactions, or release-facing QA guidance. This template is the per-PR record: copy the closest matrix category here, then record what was checked, what was skipped, what evidence status applies, and any browser-capable handoff.

- PR category:
- Evidence status, for example `not applicable`, `source review`, `rendered/browser checked`, or `browser-capable handoff`:
- Environment or state, including source-only, rendered artifact, browser, viewport, or forced-colors context when relevant:
- Evidence used:
- Remaining browser-capable check, if any:
- Screen or artifact checked:
- Viewports or states checked:
- Skipped full-checklist areas and reason:
- Follow-up needed:

For docs-only or spec-only changes, it is fine to write `not applicable` when the changed text does not claim a rendered UI state.

## UI / Visual Evidence

Use this section only when the PR changes visible UI, layout, copy that affects a control, or a visual reference. Docs-only API wording and non-visual code changes can mark this as not applicable.

For static visual docs or docs image changes, use the `Static visual docs or docs image` category in `docs/manual_qa_pr_smoke_matrix.md` to decide the evidence boundary, then record here whether source diff, rendered visual confirmation, or a browser-capable handoff was used. Use the same evidence-status wording as the focused manual QA section. This does not replace browser evidence for runtime UI, layout, or control-copy changes.

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
