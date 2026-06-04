# Sandbox Rails app verification

This guide describes a small Rails application setup for checking Rails Table Preferences before integrating it into a real business application.

Use this sandbox to separate gem behavior from host application complexity such as authentication, existing CSS, existing JavaScript, authorization, and custom search objects.

## Goal

Verify that the gem works end-to-end in a minimal Rails app:

- install generator
- migration
- engine mount
- copied or package-entrypoint JavaScript and CSS
- editor rendering
- table display changes
- preset save/load/delete
- filter UI
- sort UI
- basic controller params integration
- existing search form hidden-field roundtrip

## Recommended directory layout

Keep both repositories under the WSL/Linux home directory for better filesystem performance:

```text
~/rails_table_preferences
~/rtp_sandbox
```

Avoid placing the sandbox under `/mnt/c/...` when possible, because Rails, Bundler, and file watching are usually slower there.

## 1. Create the sandbox app

From a directory next to the gem repository:

```bash
cd ~
rails new rtp_sandbox
cd rtp_sandbox
```

If you want a specific Rails version, install/use that Rails version before creating the app.

## 2. Point the sandbox at the local gem

Add the local gem path to the sandbox `Gemfile`:

```ruby
gem "rails_table_preferences", path: "../rails_table_preferences"
```

Then run:

```bash
bundle install
```

## 3. Add a simple owner model

The default owner model is `User`, so create a minimal users table:

```bash
bin/rails generate model User name:string
```

Add a simple current user method to `app/controllers/application_controller.rb`:

```ruby
class ApplicationController < ActionController::Base
  helper_method :current_user

  private

  def current_user
    User.first_or_create!(name: "Sandbox User")
  end
end
```

This is only for sandbox verification. Real applications should use their normal authentication method.

### If the host app does not use `User` / `current_user`

Keep the same overall sandbox flow and only swap the owner model and current-owner method.

For example, if the host app uses `Customer` and `current_customer`:

```bash
bin/rails generate model Customer name:string
```

```ruby
class ApplicationController < ActionController::Base
  helper_method :current_customer

  private

  def current_customer
    Customer.first_or_create!(name: "Sandbox Customer")
  end
end
```

When you reach the install step, use the matching owner model and initializer settings:

```bash
bin/rails generate rails_table_preferences:install --owner-model customers
```

```ruby
RailsTablePreferences.configure do |config|
  config.owner_model = :customers
  config.current_user_method = :current_customer
end
```

After that, the rest of this guide stays the same. The bundled editor, copied demo screen, and mounted JSON API all use the same configured current-owner method, so make sure it returns a persisted owner record before opening the sandbox screen. For more detail, see [Quick start](quick_start.md) and [Demo screen generator](demo.md).

## 4. Install Rails Table Preferences

For the default `User` owner model:

```bash
bin/rails generate rails_table_preferences:install
```

If you are following the non-`User` path above, use the matching `--owner-model` option instead and keep the initializer aligned with the same owner method.

Confirm these files were generated:

```text
config/initializers/rails_table_preferences.rb
db/migrate/*_create_table_preferences.rb
app/javascript/controllers/rails_table_preferences_controller.js
app/assets/stylesheets/rails_table_preferences.css
```

### If the sandbox app uses Vite / `app/frontend`

The generator still copies `app/javascript/controllers/rails_table_preferences_controller.js` for the default `stimulus-rails` path. If the sandbox app registers Stimulus from `app/frontend/entrypoints/application.js` instead, keep that existing Stimulus application and register the packaged controller from the gem entrypoint:

```js
import RailsTablePreferencesController from "rails_table_preferences/controller"
application.register("rails-table-preferences", RailsTablePreferencesController)
```

Also confirm the bundler can resolve `rails_table_preferences` and `rails_table_preferences/controller` to the gem's packaged `app/javascript/rails_table_preferences/*` files. Use the detailed resolver example in [JavaScript entrypoints](javascript_entrypoints.md) when the sandbox app does not already provide that alias.

Use one path per sandbox app:

- default `stimulus-rails`: rely on the copied controller under `app/javascript/controllers`
- Vite / `app/frontend`: register the packaged controller from the gem entrypoint

Do not start a second Stimulus application just for Rails Table Preferences. For the broader install flow, see [Quick start](quick_start.md) and [JavaScript entrypoints](javascript_entrypoints.md).

Mount the engine in `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount RailsTablePreferences::Engine, at: "/rails_table_preferences"
end
```

Run migrations:

```bash
bin/rails db:migrate
```

## 5. Create a simple Order model

```bash
bin/rails generate model Order order_no:string customer_name:string delivery_date:date status:string amount:integer internal_cost:integer memo:text
bin/rails db:migrate
```

Seed a few records in `db/seeds.rb`:

```ruby
Order.find_or_create_by!(order_no: "A001") do |order|
  order.customer_name = "山田商事"
  order.delivery_date = Date.current
  order.status = "未出荷"
  order.amount = 12000
  order.internal_cost = 8000
  order.memo = "長い備考テキストの表示確認用です。"
end

Order.find_or_create_by!(order_no: "A002") do |order|
  order.customer_name = "田中物流"
  order.delivery_date = Date.current + 1.day
  order.status = "出荷済"
  order.amount = 34000
  order.internal_cost = 21000
  order.memo = "列幅と省略表示の確認に使います。"
end
```

Run:

```bash
bin/rails db:seed
```

## 6. Add simple search/order scopes

For controller params integration testing, add simple methods to `app/models/order.rb`:

```ruby
class Order < ApplicationRecord
  def self.search(params)
    relation = all

    if params[:search_word].present?
      relation = relation.where("customer_name LIKE ?", "%#{sanitize_sql_like(params[:search_word])}%")
    end

    if params[:status].present?
      relation = relation.where(status: params[:status])
    end

    if params[:from_delivery_date].present?
      relation = relation.where("delivery_date >= ?", params[:from_delivery_date])
    end

    if params[:to_delivery_date].present?
      relation = relation.where("delivery_date <= ?", params[:to_delivery_date])
    end

    relation
  end

  def self.order_by(sort)
    case sort.to_s
    when "order_no"
      order(order_no: :asc)
    when "-order_no"
      order(order_no: :desc)
    when "customer_name"
      order(customer_name: :asc)
    when "-customer_name"
      order(customer_name: :desc)
    when "delivery_date"
      order(delivery_date: :asc)
    when "-delivery_date"
      order(delivery_date: :desc)
    when "amount"
      order(amount: :asc)
    when "-amount"
      order(amount: :desc)
    else
      order(order_no: :asc)
    end
  end
end
```

## 7. Create an Orders screen

Create a controller:

```bash
bin/rails generate controller Orders index
```

Update `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  root "orders#index"
  resources :orders, only: [:index]

  mount RailsTablePreferences::Engine, at: "/rails_table_preferences"
end
```

Update `app/controllers/orders_controller.rb`:

```ruby
class OrdersController < ApplicationController
  def index
    @table_columns = order_table_columns
    @table_preference_settings = rails_table_preference_settings(
      table_key: :orders,
      name: params[:table_preference_name]
    )

    preference_params = rails_table_preference_params(
      table_key: :orders,
      name: params[:table_preference_name],
      columns: @table_columns
    )

    merged_params = params.to_unsafe_h.merge(preference_params)
    @orders = Order.search(merged_params).order_by(merged_params["sort"] || params[:sort])
  end

  private

  def order_table_columns
    [
      table_preferences_column(:order_no, label: "受注番号", default_width: 120, sortable: true),
      table_preferences_column(
        :customer_name,
        label: "得意先名",
        default_width: 240,
        default_truncate: 20,
        filter: { type: :text, param: :search_word },
        sortable: true
      ),
      table_preferences_column(
        :delivery_date,
        label: "納品日",
        default_width: 140,
        filter: { type: :date, from_param: :from_delivery_date, to_param: :to_delivery_date },
        sortable: true
      ),
      table_preferences_column(
        :status,
        label: "状態",
        default_width: 120,
        filter: { type: :select, param: :status, options: ["未出荷", "出荷済"] },
        sortable: true
      ),
      table_preferences_column(:amount, label: "金額", default_width: 120, sortable: true),
      table_preferences_column(:memo, label: "備考", default_width: 260, default_truncate: 24),
      table_preferences_column(:internal_cost, label: "内部原価", ignored: true)
    ]
  end
end
```

Update `app/views/orders/index.html.erb`:

```erb
<h1>受注一覧</h1>

<%= table_preferences_editor(
  table_key: :orders,
  name: params[:table_preference_name] || "default",
  settings: @table_preference_settings,
  columns: @table_columns,
  title: "受注一覧の表示設定"
) %>

<%= form_with url: orders_path, method: :get do %>
  <%= text_field_tag :search_word, params[:search_word], placeholder: "得意先名" %>

  <%= table_preferences_hidden_fields(
    settings: @table_preference_settings,
    columns: @table_columns
  ) %>

  <%= submit_tag "検索" %>
<% end %>

<%= table_preferences_table_tag(
  table_key: :orders,
  name: params[:table_preference_name] || "default",
  settings: @table_preference_settings,
  columns: @table_columns,
  class: "table"
) do %>
  <thead>
    <tr>
      <th data-rails-table-preferences-column-key="order_no">受注番号</th>
      <th data-rails-table-preferences-column-key="customer_name">得意先名</th>
      <th data-rails-table-preferences-column-key="delivery_date">納品日</th>
      <th data-rails-table-preferences-column-key="status">状態</th>
      <th data-rails-table-preferences-column-key="amount">金額</th>
      <th data-rails-table-preferences-column-key="memo">備考</th>
    </tr>
  </thead>
  <tbody>
    <% @orders.each do |order| %>
      <tr>
        <td data-rails-table-preferences-column-key="order_no"><%= order.order_no %></td>
        <td data-rails-table-preferences-column-key="customer_name"><%= order.customer_name %></td>
        <td data-rails-table-preferences-column-key="delivery_date"><%= l(order.delivery_date) if order.delivery_date %></td>
        <td data-rails-table-preferences-column-key="status"><%= order.status %></td>
        <td data-rails-table-preferences-column-key="amount"><%= number_with_delimiter(order.amount) %></td>
        <td data-rails-table-preferences-column-key="memo"><%= order.memo %></td>
      </tr>
    <% end %>
  </tbody>
<% end %>
```

The search form is intentionally small: the visible `search_word` field remains user-entered host-app search state, while `table_preferences_hidden_fields(...)` submits saved Rails Table Preferences filter and sort state as ordinary GET params. The controller still owns the merge order and query execution through `rails_table_preference_params`, `Order.search`, and `Order.order_by`; this sandbox step only confirms that saved preference state can roundtrip through an existing form without turning the guide into a full search UI tutorial.

For the generated demo version of the same hidden-field idea, see [Demo screen generator](demo.md). For the broader host-app checklist, see [Manual QA checklist](manual_qa.md#13-existing-search-form-integration). For adapter-specific params such as Ransack, see [Controller integration](controller_integration.md#hidden-fields-for-existing-search-forms) and [Filter adapters](filter_adapters.md).

## 8. Start the server

```bash
bin/rails server
```

Open:

```text
http://localhost:3000
```

## 9. Browser checks

Confirm the following:

- [ ] The editor appears above the table.
- [ ] Column labels are Japanese.
- [ ] `internal_cost` does not appear in the editor.
- [ ] Apply hides and shows columns.
- [ ] Editor row drag changes column order.
- [ ] Table header drag changes column order.
- [ ] Header resize handle changes column width.
- [ ] Long memo text is truncated.
- [ ] Save persists settings.
- [ ] Reload applies saved settings.
- [ ] Save as new creates another preset.
- [ ] Preset selection loads a named preset.
- [ ] Delete removes a preset.
- [ ] Filter panel opens for filterable columns.
- [ ] Header click cycles sort state on sortable columns.
- [ ] Filter button click does not accidentally sort.
- [ ] Resize/drag does not accidentally sort.
- [ ] Save a filter or sort preference, reload, and confirm the search form includes hidden fields for that saved state.
- [ ] Submit the search form with a visible `search_word` value and confirm the URL keeps that user-entered value together with the hidden saved preference params.
- [ ] Confirm saved filter/sort params are applied through `Order.search` / `Order.order_by`, while the sandbox does not add a new query builder or full host-app search workflow.

## 10. Network checks

Use browser devtools to confirm:

- [ ] `GET /rails_table_preferences/preferences/orders` returns JSON.
- [ ] `POST /rails_table_preferences/preferences/orders` creates a preference.
- [ ] `GET /rails_table_preferences/preferences/orders/default` loads a preference.
- [ ] `PATCH /rails_table_preferences/preferences/orders/default` updates a preference.
- [ ] `DELETE /rails_table_preferences/preferences/orders/<name>` deletes a preference.
- [ ] Requests include the CSRF token.
- [ ] Requests do not redirect to login.

## 11. After sandbox verification

After this sandbox works, move to a real host application screen and run the [Manual QA checklist](manual_qa.md).

When sandbox verification finds a bug, record:

```text
Rails version:
Ruby version:
Browser:
Exact action:
Expected result:
Actual result:
Console error:
Network request/response:
Relevant logs:
```
