# Editor action group narrow smoke

Use this focused smoke when a PR touches bundled editor action grouping, action copy, action hints, or manual QA evidence around narrow screens. It supplements `manual_qa.md` and `manual_qa_pr_smoke_matrix.md`; it does not replace rendered browser evidence when a PR claims a visual fix.

This note is a focused PR-evidence aid, not a package verification required doc. Keep it reachable from PR smoke guidance for editor action-group changes without promoting it into `PackageVerifier::REQUIRED_PATHS` unless it becomes a primary packaged docs entry point.

## Scope

This smoke is limited to the bundled editor action rows and their grouping boundary:

- visibility bulk actions
- primary apply action
- save and save-as-new actions
- maintenance actions such as delete, show all, and reset

It does not cover editor row label wrapping, filter panel reachability, drag-and-drop behavior, table header resize, preset selector loading, or full async preset workflows.

## Representative labels

Check at least one Japanese label set long enough to pressure wrapping and one default-label state so both localized copy and the baseline UI are visible.

Suggested examples:

- `現在の表示に反映する操作`
- `設定を保存する操作`
- `保存済み設定の削除や初期設定に戻す操作`
- `テーブル初期設定に戻す`

If a host app overrides labels or hints, include the longest action label and the longest hint that appears near the action groups.

## Viewports or containers

Use real browser evidence when available. If the PR is docs-only or browser access is unavailable, record a browser-capable handoff instead of claiming visual confirmation.

Recommended widths:

- 390px equivalent
- 375px equivalent
- 320px equivalent
- Any narrow host-app container that is smaller than the full viewport

## What to confirm

- The visibility, primary, save, and maintenance groups remain visually distinguishable.
- Maintenance actions do not appear to belong to the Apply or Save area.
- Long labels and hints wrap before they overlap neighboring buttons or groups.
- Buttons keep usable tap and keyboard targets at narrow widths.
- Focus-visible styling remains discoverable when tabbing through every action group.
- The status region remains separate from the action groups and does not cover controls.
- The editor row long-label smoke remains a separate check; do not treat row wrapping as covered by this action-group smoke.

## Evidence to record

In the PR body or comment, record:

- Label or locale examples used.
- Widths or container sizes checked.
- Evidence type: screenshot, browser notes, focused system spec, DOM assertion, source-level invariant, or browser-capable handoff.
- Whether CSS or action markup changed.
- Whether forced-colors or high-contrast mode was checked or handed off.
- Any skipped browser checks and why they were skipped.

## Escalation

Escalate to broader design review if the action groups only fit by merging maintenance actions into the Apply/Save area, hiding destructive actions, shrinking buttons below usable size, changing async preset behavior, or requiring a new action layout pattern.