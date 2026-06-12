# JavaScript entrypoints

Rails Table Preferences ships JavaScript integration paths for the bundled Stimulus controller and a stylesheet package subpath for bundler-based host apps.

## Default stimulus-rails path

The install generator copies the bundled controller into the host application:

```text
app/javascript/controllers/rails_table_preferences_controller.js
```

For Rails applications using the default `stimulus-rails` manifest loader, files ending in `_controller.js` under `app/javascript/controllers` are usually registered automatically. In that setup, no extra import is needed after running the install generator.

If the host app will register the package entrypoint instead, skip this copied file during install:

```bash
bin/rails generate rails_table_preferences:install --skip-javascript
```

## Vite / app/frontend path

For apps that use Vite and an entrypoint such as `app/frontend/entrypoints/application.js`, use the existing `--skip-javascript` generator option and register the controller explicitly from the gem package entrypoint:

```bash
bin/rails generate rails_table_preferences:install --skip-javascript
```

```js
import { Application } from "@hotwired/stimulus"
import RailsTablePreferencesController from "rails_table_preferences/controller"

const application = Application.start()
application.register("rails-table-preferences", RailsTablePreferencesController)
```

If the host app already starts Stimulus elsewhere, reuse that existing `application` and only add `application.register(...)` here. Do not call `Application.start()` a second time from the same host app.

The package root also exposes the same controller as a named export:

```js
import { RailsTablePreferencesController } from "rails_table_preferences"
```

Use the package entrypoint when the host app should not depend on a copied controller path under `app/javascript/controllers` from an `app/frontend` entrypoint.

### Package metadata boundary

The import specifiers above are backed by the `package.json` file that is packaged inside the Ruby gem. That file currently uses `private: true` and `version: "0.0.0"` because it is resolver metadata for gem-packaged JavaScript and stylesheet entrypoints, not a promise that Rails Table Preferences is published as a separate npm package.

Host apps should rely on the documented `exports` specifiers, `rails_table_preferences`, `rails_table_preferences/controller`, and `rails_table_preferences/styles.css`, plus their bundler alias or resolver configuration. Do not infer npm distribution, npm semver, or a JavaScript package release policy from the packaged `package.json`; the gem release version remains the Ruby gem version.

### Stylesheet boundary

The package metadata now exports `rails_table_preferences/styles.css` for host apps that want a bundler import alongside `rails_table_preferences/controller`:

```js
import "rails_table_preferences/styles.css"
```

That subpath points at the same packaged default stylesheet that the install generator can copy to `app/assets/stylesheets/rails_table_preferences.css`. It is a resolver-friendly way to load the shipped baseline CSS from Vite or another bundler; it is not a new theme system, CSS Modules contract, Sass pipeline, or npm distribution policy.

If the host app keeps the generated stylesheet, load the copied `app/assets/stylesheets/rails_table_preferences.css` through the host app's normal asset path. If the host app uses `--skip-stylesheets`, it can either import `rails_table_preferences/styles.css` through the package resolver or provide equivalent host-owned CSS for the editor, table state cues, resize handles, fixed-column hooks, and any local theme integration.

The stylesheet and controller decisions remain independent. A conventional `stimulus-rails` app can keep copied JavaScript and copied CSS. A Vite app can use the package controller and package stylesheet. A host app with custom layout or branding can use the package controller while owning CSS locally.

### Package-only controller boundary

The package entrypoint subclasses the copied controller. Shared editor behavior belongs in `app/javascript/controllers/rails_table_preferences_controller.js`; package-import adapter behavior belongs in `app/javascript/rails_table_preferences/controller.js`.

Current package-only behavior is intentionally small:

- `filterOperatorLabelsValue` allows package-entrypoint users to override bundled filter operator labels without editing a copied controller.
- Sortable header handling preserves host-provided `title` attributes while still generating sort hints for untitled headers.
- Table-header drag reorder remains package-entrypoint behavior for managed header cells, and columns with interactive header content can opt out with `draggable: false`; use [Header drag reorder](header_drag_reorder.md) for that boundary.
- Resize handles also listen for `Enter`, Space, and legacy `Spacebar` key presses and route them to the packaged keyboard auto-fit behavior after the base controller installs the handles.
- Lifecycle events such as `rails-table-preferences:applied`, `rails-table-preferences:saved`, `rails-table-preferences:loaded`, `rails-table-preferences:deleted`, and `rails-table-preferences:error` are dispatched by the package entrypoint. Host apps that register the copied controller directly should not assume the same event surface unless they port that behavior into their copied or replacement controller.
- `rails-table-preferences:error` exposes stable operation labels in `event.detail.action`; use [JavaScript controller notes](javascript_controller.md#host-app-lifecycle-events) for the current action list and fallback meaning.

Do not assume those package-only values, overrides, events, or keyboard affordances exist when an application registers the copied controller directly. If a behavior must work in both paths, keep it in the copied controller and cover it as base controller behavior. If it is only needed by package import users, keep it in the package entrypoint and document the boundary here.

The current contract boundary is:

| Surface | Copied controller path | Package entrypoint path | Host-app guidance |
| --- | --- | --- | --- |
| Source ownership | Host app owns the generated `app/javascript/controllers/rails_table_preferences_controller.js` copy after install. | Gem owns `app/javascript/rails_table_preferences/controller.js`, which subclasses the copied-controller source shipped in the gem. | Use the copied path when local patches are expected. Use the package entrypoint when the app wants packaged behavior updates through the gem. |
| Filter operator labels | Uses the base controller defaults. A copied or replacement controller is needed for controller-side operator vocabulary changes not exposed by base values. | Adds `filterOperatorLabelsValue` so packaged-controller tables can override operator text through a root JSON value. | Use locale/root values for wording-only operator labels on the package path; use copied JavaScript for copied-controller or behavior changes. |
| Sortable header `title` attributes | Base sort setup may replace generated title text while it manages sort hints. | Preserves host-provided nonblank `title` values and restores them after sort state sync. | Prefer the package entrypoint when host-rendered header titles must survive packaged sort controls. Validate copied-controller screens separately. |
| Resize handle keyboard auto-fit | Base resize handles are generated and pointer-oriented. | Adds keyboard auto-fit on resize handles for `Enter`, Space, and legacy `Spacebar`. | Treat this as package-entrypoint-only unless a future issue deliberately moves the keyboard affordance into the base controller. |
| Lifecycle events | Copied-controller registrations do not receive the package-entrypoint lifecycle event surface unless the host app ports that behavior into their copied or replacement controller. | Dispatches package-entrypoint lifecycle events such as `applied`, `saved`, `loaded`, `deleted`, and `error` with stable detail payloads, including documented `error` action labels. | Check host-app event listeners against the registration path that actually owns the screen. Use JavaScript controller notes for the `error` action list. |
| Future additive behavior | Should only receive behavior that must work for generated copied-controller users too. | May receive package-import adapter behavior, but each addition must be documented here. | If a difference becomes important for both paths, open a focused follow-up rather than silently expanding one path in place. |

If this table reveals a behavior that should be shared by both paths, keep this Issue as documentation only and split the implementation into a follow-up with its own compatibility and test plan. That follow-up should name whether it is a feature change, a quality/spec guard, or another docs-only clarification.

When future package-entrypoint behavior is added, update this list and re-run the entrypoint-specific manual checks for lifecycle events, sortable header titles, filter operator label overrides, and resize handle keyboard auto-fit. The copied controller path should still be checked separately when a host app registers the generated `app/javascript/controllers/rails_table_preferences_controller.js` file.

### Resolve the gem entrypoint explicitly

Vite does not automatically resolve `app/javascript` or `app/assets` files that live inside a Ruby gem. When the host app imports `rails_table_preferences`, `rails_table_preferences/controller`, or `rails_table_preferences/styles.css`, add aliases or an equivalent bundler resolver that points those specifiers at the installed gem.

A minimal `vite.config.ts` example looks like this:

```ts
import { execSync } from "node:child_process"
import { fileURLToPath } from "node:url"
import { defineConfig } from "vite"

function gemPath(name: string) {
  return execSync(`bundle show ${name}`, { encoding: "utf-8" }).trim()
}

function gemFilePath(name: string, entrypoint: string) {
  return fileURLToPath(new URL(entrypoint, `file://${gemPath(name)}/`))
}

export default defineConfig({
  resolve: {
    alias: [
      { find: /^rails_table_preferences$/, replacement: gemFilePath("rails_table_preferences", "app/javascript/rails_table_preferences/index.js") },
      { find: /^rails_table_preferences\/controller$/, replacement: gemFilePath("rails_table_preferences", "app/javascript/rails_table_preferences/controller.js") },
      { find: /^rails_table_preferences\/styles\.css$/, replacement: gemFilePath("rails_table_preferences", "app/assets/stylesheets/rails_table_preferences.css") }
    ]
  }
})
```

Any equivalent resolver is fine. The important part is that the host app's bundler can find the gem's packaged `app/javascript/rails_table_preferences/*` and `app/assets/stylesheets/rails_table_preferences.css` files.

### TypeScript module declarations

The package entrypoints include minimal `.d.ts` files for `rails_table_preferences` and `rails_table_preferences/controller`. They describe the import shape enough for a TypeScript host app to register the bundled Stimulus controller without adding local declarations only for these package imports:

```ts
import RailsTablePreferencesController from "rails_table_preferences/controller"
import { RailsTablePreferencesController as NamedRailsTablePreferencesController } from "rails_table_preferences"
```

The package root also re-exports lifecycle event detail types such as `RailsTablePreferencesEventDetail` and `RailsTablePreferencesEventName`. When a TypeScript host app listens for package-entrypoint lifecycle events, keep the listener boundary local by narrowing the DOM event to `CustomEvent<RailsTablePreferencesEventDetail>` and use [Host app lifecycle events](javascript_controller.md#host-app-lifecycle-events) for the current typed example, event names, and action meanings.

Those lifecycle event types describe the package entrypoint surface only. Host apps that register a copied or replacement controller should not import them as proof that the copied controller dispatches the same events unless that app has ported the package-entrypoint event behavior too.

These packaged declarations intentionally stay narrow. They identify the exported Stimulus controller class and lifecycle event detail surface, but do not type every controller method, private implementation detail, copied-controller customization, or host-app replacement controller API.

If the host app uses an older gem version without packaged declarations, or if it replaces the controller and wants richer local typing for custom methods, keep a local declaration file in the host app. For example, `app/frontend/types/rails_table_preferences.d.ts` can still refine the app-specific contract as long as the directory is included by the app's `tsconfig.json`.

## Choosing between copied assets and the package entrypoint

Keep the copied controller and stylesheet path when the host app is a conventional `stimulus-rails` app, wants to inspect or patch the generated files locally, already depends on copied JavaScript or CSS for behavior or layout changes that are not exposed through packaged entrypoints, or needs the generated assets and package entrypoints to have exactly the same behavior until a parity follow-up is implemented.

Prefer the package controller entrypoint when the host app starts Stimulus from Vite, `app/frontend`, or another bundled JavaScript entrypoint, or when the app wants to pick up packaged controller improvements without refreshing a copied controller file. Use `--skip-javascript` for this path so the generator still creates the migration and initializer while leaving controller registration to the host app entrypoint.

Prefer the package stylesheet entrypoint when the host app wants the shipped baseline CSS through the same bundler/resolver path as the controller. Use `--skip-stylesheets` only when the app either imports `rails_table_preferences/styles.css` or intentionally owns equivalent CSS.

The package controller path is also the lighter choice for wording and label changes that can stay in Rails locale files or controller-root values such as `data-rails-table-preferences-filter-operator-labels-value`.

Do not treat package entrypoints as replacements for every customization. Host apps still need copied ERB when markup, helper-text placement, or status-region structure changes. Host apps still need copied or replacement JavaScript when they change controller behavior, add new operator semantics, or use a registration path that intentionally does not include the packaged subclass. Host apps still need local CSS when they want product-specific density, branding, sticky-layout polish, or theme integration beyond the shipped baseline.

## Moving from a copied controller to the package entrypoint

When an existing host app moves from the copied controller to `rails_table_preferences/controller`, check these items before removing the copied file from active registration:

- The host app has exactly one Stimulus application registration for `rails-table-preferences`.
- The bundler resolves `rails_table_preferences/controller`, `rails_table_preferences`, and `rails_table_preferences/styles.css` if those package specifiers are used.
- The host app still loads either the generated stylesheet, the package stylesheet export, or equivalent host-app CSS.
- Any local changes in `app/javascript/controllers/rails_table_preferences_controller.js` have been classified as wording, markup, or behavior changes.
- Wording-only changes have moved to Rails locale keys or controller-root label values where possible.
- Markup changes remain in copied ERB, not in the package entrypoint import.
- Behavior changes that are not represented by packaged root values stay in a host-owned controller or copied JavaScript path.
- Screens that rely on packaged-only root values, such as `data-rails-table-preferences-filter-operator-labels-value`, are registered through the package entrypoint.
- Host-app listeners that depend on Rails Table Preferences lifecycle events have been checked against the package entrypoint, not only a copied controller registration.
- Screens that rely on package-only sortable-title preservation or resize-handle keyboard auto-fit have manual checks covering those behaviors after the registration switch.

After switching registration, re-run the manual checks for editor load, preset save/load/delete, lifecycle event listeners, filter panels, sort controls, resize handles, Turbo reconnects, and any screen-specific label overrides.

## Turbo Drive and Turbo Frame checks

Rails Table Preferences does not need a Turbo-specific adapter when the host app already renders the editor and table through normal server-side HTML. The bundled controller is a Stimulus controller, so Turbo Drive navigation and Turbo Frame replacement should reconnect it as long as the rendered HTML still includes the same controller root and values.

When a table preference surface is rendered inside a Turbo Frame or replaced after Turbo navigation, check that the new HTML includes:

- `data-controller="rails-table-preferences"`
- `data-rails-table-preferences-table-key-value`
- `data-rails-table-preferences-name-value` when the page uses named presets or a preset selector
- `data-rails-table-preferences-columns-value`
- `data-rails-table-preferences-settings-value`
- the collection and member URL values used by the bundled JSON API
- matching `data-rails-table-preferences-column-key` values on managed headers and cells

Keep `table_key`, preference `name`, current settings, and column definitions stable across the Turbo-rendered response for the same logical screen. If a frame response changes those values accidentally, the controller may reconnect successfully but appear to load a different preset, lose saved column order, or stop applying display changes to the intended table.

For Turbo Frames, prefer replacing the editor and its matching table together, or make sure both pieces receive the same current settings and column definitions from the controller action that renders the frame. Rails Table Preferences does not own the host app's frame routing, Turbo Stream responses, or query execution; it only reads the values present in the reconnected DOM.

If behavior looks stale after navigation, inspect the frame response HTML first, then compare it with the manual root contract in [JavaScript controller notes](javascript_controller.md). Runtime workarounds should usually wait until the host app has confirmed the reconnecting DOM is complete and consistent.

## Custom controller path

For jsbundling or a custom Stimulus setup that still uses the copied file, import and register it manually:

```js
import RailsTablePreferencesController from "./controllers/rails_table_preferences_controller"
application.register("rails-table-preferences", RailsTablePreferencesController)
```

If the host application wants to maintain its own JavaScript implementation, skip copying during install and register a controller with the same Stimulus name:

```bash
bin/rails generate rails_table_preferences:install --skip-javascript
```

That is the same install option used by package entrypoint apps; the difference is only whether the host app registers `rails_table_preferences/controller` or a compatible host-owned controller.

Rails Table Preferences does not require importmap-specific setup.
