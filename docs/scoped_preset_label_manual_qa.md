# Scoped preset label manual QA

Use this companion note when a change touches scoped preset selector copy, seeded demo presets, or host-app scope labels. It narrows the manual check for long `scope_label` values without changing the preset selection contract.

## Review focus

Confirm that long role or organization labels remain understandable in the bundled preset selector at desktop and narrow widths.

The selector may show options such as:

- `共有ビュー [shared]`
- `担当ビュー [role:operations-with-long-display-name]`
- `東京組織ビュー [organization:tokyo-hq-enterprise-division]`

The goal is not to redesign the select control. The goal is to make sure the visible option text still distinguishes owner, shared, role, and organization presets well enough for manual verification.

## Suggested setup

Use the generated demo or a representative host app screen with scoped presets enabled.

- Seed or return at least one owner preset, one shared preset, one role preset, and one organization preset.
- Include one long `scope_label` for a role or organization preset.
- Include one long preset name so the review covers both name length and scope mark length.
- Keep the same saved settings payload and preset precedence rules; this check is only about selector readability.

## Desktop checks

- [ ] The preset selector remains usable with long scoped option text.
- [ ] Owner, shared, role, and organization options can still be distinguished from the option text.
- [ ] The default marker remains readable when a scoped option is also long.
- [ ] The preset name input and action buttons do not overlap the selector in the bundled editor layout.
- [ ] The helper copy still explains that the selector loads or switches the saved preset, not the save target name.

## Narrow-width checks

Check at 320px, 375px, and 390px-equivalent widths or inside a similarly narrow container.

- [ ] The selector does not cover the preset name input, default checkbox, action buttons, maintenance actions, or helper copy.
- [ ] The option text may truncate according to the browser's native select behavior, but the selected value still gives enough context to identify the active scope.
- [ ] Long labels do not push the editor action row into overlapping controls.
- [ ] The read-only scoped preset hint remains visible when selecting a shared, role, or organization preset.

## Accessibility checks

- [ ] Keyboard users can focus the selector and move through long owner/shared/role/organization options.
- [ ] The visible selected option and the nearby helper copy provide enough context to understand which saved preset will load.
- [ ] If the host app customizes scope labels, the custom copy still differentiates owner, shared, role, and organization presets.

## Out of scope

Do not use this check to require:

- replacing the native select with a custom combobox
- changing scoped preset precedence or write policy
- adding a scoped preset admin UI
- changing API payload shape
- redesigning the bundled editor layout
