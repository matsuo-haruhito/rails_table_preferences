# Clearing Filter and Sort State

Use `rails-table-preferences#clearFiltersAndSorts` when a table needs a lightweight "clear current search view" action that keeps display preferences in place.

The action updates only the in-memory table preference state:

- `filters` becomes `{}`.
- `sorts` becomes `[]`.
- `columns` is left as-is, including visibility, order, width, overflow, and fixed/pinned metadata.

It also closes any open bundled filter panel and reapplies the table state, so active filter buttons, sort indicators, and `aria-sort` return to neutral in the current browser view.

```erb
<button type="button" data-action="rails-table-preferences#clearFiltersAndSorts">
  Clear filters and sort
</button>
```

This action does not save the changed state by itself. Keep using the existing save or save-as-new actions when the user wants the neutral filter/sort state to become a saved preset.

## Use With Reset

Use the existing `rails-table-preferences#resetEditor` action when the user wants the whole editor to return to default display settings. That reset can restore default column visibility, order, width, overflow, filters, and sorts together.

Use `clearFiltersAndSorts` when the user wants to keep the current display layout and only remove the current filter/sort view.

## Manual QA

- Hide or resize a column, apply a filter, sort a header, then run `clearFiltersAndSorts`; confirm the column display settings remain while the filter and sort indicators become neutral.
- Open a filter panel and run the action; confirm the panel closes and the triggering filter button is no longer active.
- Run `resetEditor` afterward and confirm it still restores the full default settings rather than behaving like the narrower clear action.
- Confirm the host application's search execution still owns when cleared filter/sort params are submitted or saved; this action does not change query adapters or form submission behavior.
