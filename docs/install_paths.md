# Install path options

Use this guide when the host app has more than one reasonable installation path and you want to choose the smallest generator option set before following the full [Quick start](quick_start.md).

## Choose the smallest path

| Goal | Generator command | Follow-up docs |
| --- | --- | --- |
| Default Rails app using `stimulus-rails` controller manifests | `bin/rails generate rails_table_preferences:install` | Continue with [Quick start](quick_start.md) and mount the engine. |
| Host app uses another owner model, such as `Customer` | `bin/rails generate rails_table_preferences:install --owner-model customers` | Set `config.owner_model` and `config.current_user_method` before opening the editor, API, or demo. |
| Vite, `app/frontend`, or another bundler should import the package entrypoint | `bin/rails generate rails_table_preferences:install` | Register `rails_table_preferences/controller` from the host app entrypoint and add the resolver from [JavaScript entrypoints](javascript_entrypoints.md). |
| Host app wants to avoid copying the bundled controller | `bin/rails generate rails_table_preferences:install --skip-javascript` | Register a host-owned controller with the same Stimulus name, or import the package entrypoint manually. |
| Host app wants to avoid copying the default stylesheet | `bin/rails generate rails_table_preferences:install --skip-stylesheets` | Load equivalent host-app CSS for the editor, table state, resize handles, and fixed-column hooks. |
| Local browser verification before real screen integration | `bin/rails generate rails_table_preferences:install --with-demo` | Add the demo route manually, then follow [Demo screen generator](demo.md). |
| Local browser verification with the demo route added by the generator | `bin/rails generate rails_table_preferences:install --with-demo-route` | Open `/rails_table_preferences_demo/orders` after migration and engine mount. |

All paths still create the migration and initializer. Run `bin/rails db:migrate` after generation unless the host app is intentionally inspecting copied files before applying the database change.

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

## Package entrypoint versus copied controller

The default install copies `app/javascript/controllers/rails_table_preferences_controller.js` for apps that rely on the normal `stimulus-rails` manifest path.

Use the package entrypoint when the host app starts Stimulus from another entrypoint, such as Vite or `app/frontend`:

```js
import RailsTablePreferencesController from "rails_table_preferences/controller"

application.register("rails-table-preferences", RailsTablePreferencesController)
```

For Vite and similar bundlers, also add a resolver for `rails_table_preferences` and `rails_table_preferences/controller`. Keep [JavaScript entrypoints](javascript_entrypoints.md) as the source of truth for the full resolver example, TypeScript declaration note, and the package-only controller behavior boundary.

When choosing between the copied controller, the package entrypoint, and `--skip-javascript`, verify any screen-specific controller-root values against that boundary. Package-only values such as `data-rails-table-preferences-filter-operator-labels-value` are available only when the registered controller comes from `rails_table_preferences/controller`; host-owned or copied controller paths need their own JavaScript for equivalent behavior.

## Demo option boundary

`--with-demo` copies the demo controller and view only. Add this route yourself when you choose that path:

```ruby
get "/rails_table_preferences_demo/orders", to: "rails_table_preferences_demo/orders#index"
```

`--with-demo-route` implies `--with-demo`, copies the same demo files, and asks the generator to add the route when it is not already present.

The demo is a local verification surface. Remove the copied demo controller, view, and route before production release if the host app does not intentionally keep them.