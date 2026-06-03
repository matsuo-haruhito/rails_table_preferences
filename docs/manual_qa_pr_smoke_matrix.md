# Manual QA smoke matrix for PRs

Use this matrix when a PR is too small for the full manual QA checklist but still needs a clear browser or review evidence boundary. It complements `manual_qa.md`; it does not replace the full release or host-app launch checklist.

## How to use this matrix

1. Choose the closest PR category below.
2. Run the focused smoke items for that category.
3. Record what was checked, what was skipped, and why in the PR body or a PR comment.
4. Escalate to the full `manual_qa.md` checklist when the PR touches multiple categories, changes runtime UI behavior, changes public helper contracts, or reveals visual/accessibility concerns.

When browser capture is not available, use the strongest available substitute: focused system spec, DOM assertion, static visual reference check, source-level invariant, or a clear `needs-human` handoff. Do not describe source inspection as visual evidence when the acceptance criteria require rendered UI proof.

## PR category matrix

| PR category | Focused smoke | Evidence to record | Escalate when |
| --- | --- | --- | --- |
| Docs-only | Confirm links, commands, option names, and issue/PR references match current source. No browser smoke is required unless the doc claims a rendered state. | Docs paths checked, source-of-truth files consulted, and any intentionally skipped browser checks. | The doc changes visible UI promises, public API guarantees, or release sign-off wording. |
| Controller or bundled editor UI | Open a representative editor screen, apply one visibility/order change, and check desktop plus one narrow width for clipping, focus visibility, and helper/status copy. | Screenshot or browser notes for desktop and narrow width, plus the workflow used to apply a setting. | The PR changes async preset actions, drag/resize/filter/sort interactions, or accepted keyboard behavior. |
| Resource table helper or view partial | Render records-present and records-empty states, including all-hidden columns when relevant. Confirm captions, row/cell hooks, and `colspan` stay valid. | Rendered HTML snippet, focused view/helper spec, or browser notes for the changed table state. | The PR adds a public data hook, new helper option, custom partial contract, or tree-table behavior. |
| Generator or demo flow | Run or inspect the generator path touched by the PR, then confirm generated file, route, setup note, and demo screen guidance match. | Generator command/path, files expected to change, and whether route/setup idempotency was checked. | The PR changes install defaults, migration shape, mounted route behavior, or post-install instructions. |
| Export, hidden fields, or controller params | Exercise one representative saved preference state and confirm the outgoing payload/hidden fields/params match current docs. | Focused spec or payload sample showing included, omitted, and mapped params. | The PR changes adapter precedence, search execution assumptions, export column selection, or host-app ownership boundaries. |
| Fixed columns, grouped headers, or dense layout | Check one horizontally scrolled table, one focusable cell control, and one narrow or long-label case. | Browser notes or screenshot showing pinned/fixed overlap, focus visibility, and grouped header alignment. | The PR changes sticky offsets, z-index guidance, grouped header markup, or scroll-container assumptions. |
| Scoped presets | Confirm owner, shared, role, or organization options remain distinguishable and that read-only presets do not expose destructive actions as editable. | Selector option labels/scope notes, owner/context used, and any read-only hint checked. | The PR changes default resolution, write scope, authorization expectations, or selector grouping behavior. |

## PR comment template

```markdown
### Focused manual QA

- PR category:
- Screen or artifact checked:
- Viewports or states checked:
- Evidence:
- Skipped full-checklist areas and reason:
- Follow-up needed:
```

Keep the note short. For docs-only and spec-only changes, it is fine to say browser QA was not applicable, as long as the changed text does not claim a rendered UI state. For UI and visual reference changes, include rendered evidence or leave a `needs-human` handoff for someone with a browser-capable environment.
