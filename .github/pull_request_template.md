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
- Manual QA applicability:
- UI / visual evidence:

## Focused Manual QA

Use `docs/manual_qa_pr_smoke_matrix.md` when this PR changes browser-visible behavior, generated demo output, helper-rendered markup, JavaScript interactions, or release-facing QA guidance.

- PR category:
- Review state or handoff reason:
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
- If browser capture was unavailable, substitute evidence is listed in the PR body or comment, such as focused specs, source-level DOM assertions, static visual reference review, or human reviewer handoff.

## Existing Behavior / Compatibility

- Public API / JSON API / DB schema / authorization changes:
- Host-app responsibility boundaries:

## Risk

- Risk level:
- Rollback notes:

## Notes

-
