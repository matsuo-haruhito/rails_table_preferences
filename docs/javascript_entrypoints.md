# JavaScript entrypoints

Rails Table Preferences ships two JavaScript integration paths for the bundled Stimulus controller.

## Default stimulus-rails path

The install generator copies the bundled controller into the host application:

```text
app/javascript/controllers/rails_table_preferences_controller.js
```

For Rails applications using the default `stimulus-rails` manifest loader, files ending in `_controller.js` under `app/javascript/controllers` are usually registered automatically. In that setup, no extra import is needed after running the install generator.

## Vite / app/frontend path

For apps that use Vite and an entrypoint such as `app/frontend/entrypoints/application.js`, register the controller explicitly from the gem package entrypoint:

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

The package entrypoints include minimal `.d.ts` files for `rails_table_preferences` and `rails_table_preferences/controller`. They describe the import shape enough for a TypeScript host app to register the bundled Stimulus controller without adding local declarations only for these package imports:

```ts
import RailsTablePreferencesController from "rails_table_preferences/controller"
import { RailsTablePreferencesController as NamedRailsTablePreferencesController } from "rails_table_preferences"
```

These packaged declarations intentionally stay narrow. They identify the exported Stimulus controller class but do not type every controller method, private implementation detail, copied-controller customization, or host-app replacement controller API.

If the host app uses an older gem version without packaged declarations, or if it replaces the controller and wants richer local typing for custom methods, keep a local declaration file in the host app. For example, `app/frontend/types/rails_table_preferences.d.ts` can still refine the app-specific contract as long as the directory is included by the app's `tsconfig.json`.

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

Rails Table Preferences does not require importmap-specific setup.
