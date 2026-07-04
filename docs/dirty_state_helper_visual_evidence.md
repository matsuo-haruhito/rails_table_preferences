# Dirty-state helper visual evidence

Use this focused note when a package-entrypoint editor change needs evidence for the dirty-state helper. It complements `docs/editor_entrypoint_affordances.md` and `docs/manual_qa.md`; it does not replace the full manual QA checklist.

## Scope

The dirty-state helper is a persistent unsaved-change cue for the packaged `rails_table_preferences/controller` entrypoint. It is separate from the async `role="status"` region used for save, load, delete, reset, visibility bulk, and resize auto-fit progress or result messages.

This note only covers visual and accessibility evidence for that helper. It does not change storage payloads, preset authorization, copied-controller behavior, JSON API behavior, CSRF handling, or host-app business logic.

## Evidence setup

Use a generated demo or representative host-app screen that imports the package entrypoint and renders a table with enough editor rows to exercise wrapping.

Prefer these states for evidence:

- a long column label or long Japanese column label
- compact editor action controls visible near the helper
- an async status message visible before or after the dirty-state helper is shown
- one visible editor input change that makes the helper appear

Record the browser, operating system, build or PR, and viewport widths used.

## Desktop check

- [ ] Open the package-entrypoint editor at a desktop width.
- [ ] Change one editor input without saving.
- [ ] Confirm the dirty-state helper appears as a separate persistent cue and does not replace the async status region.
- [ ] Confirm the helper does not overlap editor controls, long labels, order inputs, width inputs, truncate inputs, or action buttons.
- [ ] Confirm a save, save as new, preset load, reset, or delete success clears the helper when the editor returns to the clean snapshot.

## Narrow viewport check

Use at least one phone-like width, preferably 375px or 390px-equivalent. If the host app uses a narrow container rather than a full viewport, record the container width.

- [ ] Confirm long labels wrap without covering the dirty-state helper or generated row controls.
- [ ] Confirm the helper remains readable when the action controls wrap.
- [ ] Confirm the helper and async status message are visually distinct when both are near the editor controls.
- [ ] Confirm the helper does not introduce horizontal scrolling beyond the editor's expected layout.

## Accessibility check

- [ ] Confirm the helper is exposed as a polite atomic live update when unsaved changes appear.
- [ ] Confirm the async `role="status"` region remains the surface for save, load, delete, reset, visibility bulk, and resize auto-fit progress or result copy.
- [ ] Confirm apply keeps the helper visible because apply updates the table but does not save the preset.
- [ ] Confirm save, save as new, preset load, read-only owner-preset fallback save, reset, and delete clear the helper after success.

## Browser-capable handoff

If the current environment cannot run a browser or capture screenshots, do not mark the visual check as complete. Leave a PR comment with:

- what source/spec evidence was checked
- which browser executable or screenshot path was unavailable
- the exact desktop and narrow viewport checks still needed
- whether a maintainer visual judgment can substitute for screenshots

Recommended comment snippet:

```markdown
Browser-capable visual evidence is still needed for the dirty-state helper. Source/docs review confirms the helper is documented as separate from the async status region, and `spec/javascript/rails_table_preferences_dirty_state_spec.rb` covers package-only target/value exposure plus save/load/delete clean transitions. This environment could not run a browser, so desktop and 375px/390px-equivalent checks for overlap, wrapping, and live-region separation remain a reviewer or maintainer task.
```

## Existing automated guard

`spec/javascript/rails_table_preferences_dirty_state_spec.rb` guards the package-entrypoint dirty-state surface: package-only target/value exposure, separation from the async status region, and representative clean transitions after save, save as new, preset load, read-only save fallback, and preset delete. Treat that as behavior evidence, not as a substitute for rendered desktop or narrow-viewport review.
