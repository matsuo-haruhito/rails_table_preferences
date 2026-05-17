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

The package root also exposes the same controller as a named export:

```js
import { RailsTablePreferencesController } from "rails_table_preferences"
```

Use the package entrypoint when the host app should not depend on a copied controller path under `app/javascript/controllers` from an `app/frontend` entrypoint.

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
