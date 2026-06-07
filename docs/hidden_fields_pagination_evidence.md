# Hidden fields pagination evidence

Use this guide when a host app submits saved filter or sort state through an existing GET search form with `table_preferences_hidden_fields(...)` and the screen also carries a pagination param such as `page`.

Rails Table Preferences renders saved filter and sort inputs. It does not decide whether pagination should restart, stay on the current page, or clamp after the host app applies the query. Keep that decision in the host app and record which policy was checked.

## What to verify

Before using the generated demo, a downstream host app, or a PR smoke as evidence, choose one representative saved preference state that changes the effective result set. Then check the existing search form from a later page, not only from page 1.

Record one of these host-app decisions:

- `clear`: the host app removes `page` before applying the saved filter or sort.
- `preserve`: the host app intentionally keeps `page` because the screen's pagination semantics require it.
- `clamp`: the host app applies the query, detects an out-of-range page, and redirects or renders a valid page.

For all three policies, confirm the hidden fields still match the saved filter and sort state, including omitted blank values, array params with `[]` names, and saved boolean `false` values when applicable.

## Where to record evidence

For the generated demo, use `docs/demo.md` as a browser-verification surface for hidden-field rendering only. The demo should not become the source of truth for host-app pagination policy because it does not own real paginator behavior.

For PRs, use the `Export, hidden fields, or controller params` row in `docs/manual_qa_pr_smoke_matrix.md`. Record the payload or hidden-field sample and add the selected pagination decision: clear, preserve, or clamp.

For real host-app adoption, use the quick host-app smoke in `docs/production_integration_checklist.md`. Repeat the search-form roundtrip from a later page and record the policy with the downstream adoption evidence template.

## Boundary

Do not change `table_preferences_hidden_fields(...)`, `rails_table_preference_params(...)`, controller adapters, or paginator behavior to satisfy this evidence check. If the host app needs different pagination behavior, implement that in the host app search flow.

See also [Controller integration](controller_integration.md#pagination-and-page-params), [Production integration checklist](production_integration_checklist.md#6-run-the-quick-host-app-smoke), and [Manual QA PR smoke matrix](manual_qa_pr_smoke_matrix.md).
