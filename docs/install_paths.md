# Install path options

Use this guide when the host app has more than one reasonable installation path and you want to choose the smallest generator option set before following the full [Quick start](quick_start.md).

## Choose the smallest path

| Goal | Generator command | Follow-up docs |
| --- | --- | --- |
| Default Rails app using `stimulus-rails` controller manifests | `bin/rails generate rails_table_preferences:install` | Continue with [Quick start](quick_start.md) and mount the engine manually, or add `--with-engine-route` when the default API path is acceptable. |
| Default install with the JSON API engine route added by the generator | `bin/rails generate rails_table_preferences:install --with-engine-route` | Run the migration, then verify the mounted API path in [Mounted JSON API](json_api.md). |
| Host app uses another owner model, such as `Customer` | `bin/rails generate rails_table_preferences:install --owner-model customers` | Set `config.owner_model` and `config.current_user_method` before opening the editor, API, or demo. |
| Vite, `app/frontend`, or another bundler should import the package entrypoint | `bin/rails generate rails_table_preferences:install --skip-javascript` | Register `rails_table_preferences/controller` from the host app entrypoint and add the resolver from [JavaScript entrypoints](javascript_entrypoints.md). |
| Host app wants to provide its own controller implementation | `bin/rails generate rails_table_preferences:install --skip-javascript` | Register a host-owned controller with the `rails-table-preferences` Stimulus name. |
| Host app wants to avoid copying the default stylesheet | `bin/rails generate rails_table_preferences:install --skip-stylesheets` | Load equivalent host-app CSS for the editor, table state, resize handles, and fixed-column hooks. |
| Local browser verification before real screen integration | `bin/rails generate rails_table_preferences:install --with-demo` | Add the demo route manually, then follow [Demo screen generator](demo.md). |
| Local browser verification with the demo route added by the generator | `bin/rails generate rails_table_preferences:install --with-demo-route` | Open `/rails_table_preferences_demo/orders` after migration and engine mount. |

All paths still create the migration and initializer. Run `bin/rails db:migrate` after generation unless the host app is intentionally inspecting copied files before applying the database change.

`--skip-javascript` only skips the copied `app/javascript/controllers/rails_table_preferences_controller.js` file. It does not remove the JavaScript requirement: the host app must still register either the package entrypoint or a compatible host-owned controller with the `rails-table-preferences` Stimulus name.

## Owner requirement for demo and API checks

The bundled editor, mounted JSON API, and copied demo screen all use the configured current-owner method. By default that is `current_user` and the owner model is `User`.

If the host app uses another owner model or method, configure both before opening the demo or testing preset persistence:

```ruby
RailsTablePreferences.configure do |config|
  config.owner_model = :customers
  config.current_user_method = :current_customer
end
```

The method must return a persisted record. `--with-demo` and `--with-demo-route` copy verification files; they do not create the owner record or bypass the normal owner lookup.

## Parent controller and mounted API boundary

The mounted engine controller inherits `RailsTablePreferences.config.parent_controller_class_name`, which defaults to the host app's `ApplicationController`. Keep that value pointed at the controller that should own authentication, CSRF handling, tenant or locale setup, and other request-wide callbacks for the mounted JSON API.

If the host app uses a separate authenticated base controller, update the initializer before production verification:

```ruby
RailsTablePreferences.configure do |config|
  config.parent_controller_class_name = "Admin::BaseController"
end
```

`current_user_method` and `scope_context_method` are called on that inherited controller, including private methods. After mounting the engine, verify the API routes through the real host-app authentication and callback boundary in [Production integration checklist](production_integration_checklist.md). For the route and payload shape, see [Mounted JSON API](json_api.md).

## Engine route option boundary

`--with-engine-route` adds this default mount line to `config/routes.rb` when the same line is not already present:

```ruby
mount RailsTablePreferences::Engine, at: "/rails_table_preferences"
```

The option is explicit opt-in. The default install path still leaves route ownership with the host app, and `--with-engine-route` does not change the initializer or infer a custom `config.mount_path`.

If the host app mounts the engine somewhere else, edit both the route and `config.mount_path` yourself so the helper-generated JSON API URLs point at the same path.

`--with-engine-route` is independent from `--with-demo-route`; use both options when a sandbox install should receive both the JSON API mount and the copied demo route in one generator run.

## Package entrypoint versus copied controller

The default install copies `app/javascript/controllers/rails_table_preferences_controller.js` for apps that rely on the normal `stimulus-rails` manifest path.

Use the package entrypoint when the host app starts Stimulus from another entrypoint, such as Vite or `app/frontend`. In that path, run the install generator with `--skip-javascript` so the app does not also receive a copied controller it will not register:

```bash
bin/rails generate rails_table_preferences:install --skip-javascript
```

Then register the package entrypoint from the host app's existing Stimulus application:

```js
import RailsTablePreferencesController from "rails_table_preferences/controller"

application.register("rails-table-preferences", RailsTablePreferencesController)
```

For Vite and similar bundlers, also add a resolver for `rails_table_preferences` and `rails_table_preferences/controller`. Keep [JavaScript entrypoints](javascript_entrypoints.md) as the source of truth for the full resolver example, TypeScript declaration note, and the package-only controller behavior boundary.

When choosing between the copied controller, the package entrypoint, and a host-owned controller, verify any screen-specific controller-root values against that boundary. Package-only values such as `data-rails-table-preferences-filter-operator-labels-value` are available only when the registered controller comes from `rails_table_preferences/controller`; host-owned or copied controller paths need their own JavaScript for equivalent behavior.

## Demo option boundary

`--with-demo` copies the demo controller and view only. Add this route yourself when you choose that path:

```ruby
get "/rails_table_preferences_demo/orders", to: "rails_table_preferences_demo/orders#index"
```

`--with-demo-route` implies `--with-demo`, copies the same demo files, and asks the generator to add the route when it is not already present.

The demo is a local verification surface. Remove the copied demo controller, view, and route before production release if the host app does not intentionally keep them.
