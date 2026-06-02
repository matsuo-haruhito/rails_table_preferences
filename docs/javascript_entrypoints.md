# JavaScript entrypoints

Rails Table Preferences ships two JavaScript integration paths for the bundled Stimulus controller.

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

The import specifiers above are backed by the `package.json` file that is packaged inside the Ruby gem. That file currently uses `private: true` and `version: "0.0.0"` because it is resolver metadata for gem-packaged JavaScript entrypoints, not a promise that Rails Table Preferences is published as a separate npm package.

Host apps should rely on the documented `exports` specifiers, `rails_table_preferences` and `rails_table_preferences/controller`, plus their bundler alias or resolver configuration. Do not infer npm distribution, npm semver, or a JavaScript package release policy from the packaged `package.json`; the gem release version remains the Ruby gem version.

### Package-only controller boundary

The package entrypoint subclasses the copied controller. Shared editor behavior belongs in `app/javascript/controllers/rails_table_preferences_controller.js`; package-import adapter behavior belongs in `app/javascript/rails_table_preferences/controller.js`.

Current package-only behavior is intentionally small:

- `filterOperatorLabelsValue` allows package-entrypoint users to override bundled filter operator labels without editing a copied controller.
- Sortable header handling preserves host-provided `title` attributes while still generating sort hints for untitled headers.
- Resize handles also listen for `Enter`, Space, and legacy `Spacebar` key presses and route them to the packaged keyboard auto-fit behavior after the base controller installs the handles.

Do not assume those package-only values, overrides, or keyboard affordances exist when an application registers the copied controller directly. If a behavior must work in both paths, keep it in the copied controller and cover it as base controller behavior. If it is only needed by package import users, keep it in the package entrypoint and document the boundary here.

When future package-entrypoint behavior is added, update this list and re-run the entrypoint-specific manual checks for sortable header titles, filter operator label overrides, and resize handle keyboard auto-fit. The copied controller path should still be checked separately when a host app registers the generated `app/javascript/controllers/rails_table_preferences_controller.js` file.

### Resolve the gem entrypoint explicitly

Vite does not automatically resolve `app/javascript` files that live inside a Ruby gem. When the host app imports `rails_table_preferences` or `rails_table_preferences/controller`, add an alias or an equivalent bundler resolver that points those specifiers at the installed gem.

A minimal `vite.config.ts` example looks like this:

```ts
import { execSync } from "node:child_process"
import { fileURLToPath } from "node:url"
import { defineConfig } from "vite"

function gemPath(name: string) {
  return execSync(`bundle show ${name}`, { encoding: "utf-8" }).trim()
}

function gemJavaScriptPath(name: string, entrypoint: string) {
  return fileURLToPath(new URL(`app/javascript/${entrypoint}`, `file://${gemPath(name)}/`))
}

export default defineConfig({
  resolve: {
    alias: [
      { find: /^rails_table_preferences$/, replacement: gemJavaScriptPath("rails_table_preferences", "rails_table_preferences/index.js") },
      { find: /^rails_table_preferences\/controller$/, replacement: gemJavaScriptPath("rails_table_preferences", "rails_table_preferences/controller.js") }
    ]
  }
})
```

Any equivalent resolver is fine. The important part is that the host app's bundler can find the gem's packaged `app/javascript/rails_table_preferences/*` files.

### TypeScript module declarations

The gem currently ships JavaScript entrypoints, not packaged `.d.ts` files. In a TypeScript host app, the Vite resolver above can make the imports work at runtime while TypeScript may still report that it cannot find declarations for `rails_table_preferences` or `rails_table_preferences/controller`.

When that happens, add a local declaration file in the host app, for example `app/frontend/types/rails_table_preferences.d.ts` or another directory included by the app's `tsconfig.json`:

```ts
declare module "rails_table_preferences/controller" {
  import { Controller } from "@hotwired/stimulus"

  const RailsTablePreferencesController: typeof Controller
  export default RailsTablePreferencesController
}

declare module "rails_table_preferences" {
  export { default, default as RailsTablePreferencesController } from "rails_table_preferences/controller"
}
```

This local declaration only describes the current package entrypoints enough for `application.register("rails-table-preferences", RailsTablePreferencesController)` and the package-root named export. It does not mean Rails Table Preferences ships official TypeScript types yet. If the host app replaces the controller or relies on custom controller methods, keep those richer declarations in the host app until the gem deliberately adds packaged type definitions.

## Choosing between copied assets and the package entrypoint

Keep the copied controller and stylesheet path when the host app is a conventional `stimulus-rails` app, wants to inspect or patch the generated files locally, or already depends on copied JavaScript for behavior changes that are not exposed through controller-root values.

Prefer the package entrypoint when the host app starts Stimulus from Vite, `app/frontend`, or another bundled JavaScript entrypoint, or when the app wants to pick up packaged controller improvements without refreshing a copied controller file. Use `--skip-javascript` for this path so the generator still creates the migration and initializer while leaving controller registration to the host app entrypoint.

This path is also the lighter choice for wording and label changes that can stay in Rails locale files or controller-root values such as `data-rails-table-preferences-filter-operator-labels-value`.

Do not treat the package entrypoint as a replacement for every customization. Host apps still need copied ERB when markup, helper-text placement, or status-region structure changes. Host apps still need copied or replacement JavaScript when they change controller behavior, add new operator semantics, or use a registration path that intentionally does not include the packaged subclass.

## Moving from a copied controller to the package entrypoint

When an existing host app moves from the copied controller to `rails_table_preferences/controller`, check these items before removing the copied file from active registration:

- The host app has exactly one Stimulus application registration for `rails-table-preferences`.
- The bundler resolves both `rails_table_preferences/controller` and, if used, `rails_table_preferences`.
- Any local changes in `app/javascript/controllers/rails_table_preferences_controller.js` have been classified as wording, markup, or behavior changes.
- Wording-only changes have moved to Rails locale keys or controller-root label values where possible.
- Markup changes remain in copied ERB, not in the package entrypoint import.
- Behavior changes that are not represented by packaged root values stay in a host-owned controller or copied JavaScript path.
- Screens that rely on packaged-only root values, such as `data-rails-table-preferences-filter-operator-labels-value`, are registered through the package entrypoint.

After switching registration, re-run the manual checks for editor load, preset save/load/delete, filter panels, sort controls, resize handles, Turbo reconnects, and any screen-specific label overrides.

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
