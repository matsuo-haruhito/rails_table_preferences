# Editor row long-label narrow smoke

Use this focused smoke when a PR touches the bundled editor row layout, display preference copy, or manual QA evidence around narrow screens. It supplements `manual_qa.md` and `manual_qa_pr_smoke_matrix.md`; it does not replace rendered browser evidence when a PR claims a visual fix.

This note is a focused PR-evidence aid, not a package verification required doc. Keep it reachable from PR smoke guidance for editor row or dense-label changes without promoting it into `PackageVerifier::REQUIRED_PATHS` unless it becomes a primary packaged docs entry point.

## Scope

This smoke is limited to editor row label wrapping at narrow widths. It does not cover action grouping, filter panel reachability, drag-and-drop behavior, table header resize, or preset action UX.

For action grouping, primary/save/maintenance separation, and long action labels near the editor buttons, use the focused [editor action group narrow smoke](editor_action_group_narrow_smoke.md) note instead of treating it as covered here.

## Representative labels

Check at least one long Japanese label and one long unbroken label so both normal wrapping and overflow pressure are visible.

Suggested examples:

- `最終承認ステータスと担当部門の長い表示名`
- `customer_reference_identifier_without_spaces_for_export_review`

## Viewports or containers

Use real browser evidence when available. If the PR is docs-only or browser access is unavailable, record a browser-capable handoff instead of claiming visual confirmation.

Recommended widths:

- 390px equivalent
- 375px equivalent
- 320px equivalent
- Any narrow host-app container that is smaller than the full viewport

## What to confirm

- The editor row label wraps or stacks before it covers controls.
- The drag handle remains visible and is not covered by label text.
- The visible checkbox remains reachable and its label is still understandable.
- Order, width, and truncate inputs keep usable tap and keyboard targets.
- Row spacing remains readable after multiple long-label rows appear together.
- The action row grouping from the bundled editor remains a separate smoke item; do not treat it as covered by this check.

## Evidence to record

In the PR body or comment, record:

- Label examples used.
- Widths or container sizes checked.
- Evidence type: screenshot, browser notes, focused system spec, source-level invariant, or browser-capable handoff.
- Whether CSS changed. If CSS did not change, state that this note only narrows the manual QA boundary.
- Any skipped browser checks and why they were skipped.

## Escalation

Escalate to broader design review if the label only fits by hiding controls, shrinking inputs below usable size, changing action group layout, or requiring drag-and-drop behavior changes.