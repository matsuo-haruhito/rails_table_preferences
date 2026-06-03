# frozen_string_literal: true

RSpec.describe "resource table rendering", type: :helper do
  before do
    RailsTablePreferences.configuration.unresolved_label_behavior = :humanize
  end

  it "renders an empty row with a visible-column colspan" do
    html = helper.resource_table_for(
      User.none,
      model: User,
      table_key: :users,
      only: %i[id name],
      include_id: true
    )

    expect(html).to include('class="rails-table-preferences-resource-table__empty-cell" colspan="2"')
    expect(html).to include("No records to display")
  end

  it "keeps the default resource table markup unwrapped" do
    html = helper.resource_table_for(
      User.none,
      model: User,
      table_key: :users,
      only: %i[name],
      class: "orders-table",
      render_editor: false
    )

    expect(html).to include('class="rails-table-preferences-resource-table orders-table"')
    expect(html).not_to include("rails-table-preferences-resource-table-scroll")
  end

  it "renders an optional scroll wrapper without moving table options" do
    html = helper.resource_table_for(
      User.none,
      model: User,
      table_key: :users,
      only: %i[name],
      class: "orders-table",
      data: { turbo_frame: "orders-frame" },
      scroll_wrapper: true,
      wrapper_options: {
        class: "orders-scroll",
        data: { role: "resource-scroll" },
        aria: { label: "Scrollable orders" }
      },
      render_editor: false
    )

    expect(html).to include('class="rails-table-preferences-resource-table-scroll orders-scroll"')
    expect(html).to include('data-role="resource-scroll"')
    expect(html).to include('aria-label="Scrollable orders"')
    expect(html).to include('class="rails-table-preferences-resource-table orders-table"')
    expect(html).to include('data-turbo-frame="orders-frame"')
  end

  it "uses the localized empty copy" do
    I18n.with_locale(:ja) do
      html = helper.resource_table_for(User.none, model: User, table_key: :users, only: %i[name])

      expect(html).to include('class="rails-table-preferences-resource-table__empty-cell" colspan="1"')
      expect(html).to include("表示できるレコードがありません")
    end
  end

  it "keeps non-empty resource tables readable" do
    user = User.create!(name: "Alice")

    html = helper.resource_table_for(User.where(id: user.id), model: User, table_key: :users, only: %i[name])

    expect(html).to include("Alice")
    expect(html).not_to include("rails-table-preferences-resource-table__empty-row")
  end

  it "adds filter type data hooks to inferred resource table cells" do
    user = User.create!(name: "Alice")

    html = helper.resource_table_for(User.where(id: user.id), model: User, table_key: :users, only: %i[name])

    expect(html).to include('data-rails-table-preferences-column-key="name"')
    expect(html).to include('data-rails-table-preferences-filter-type="text"')
  end

  it "omits the filter type data hook when column metadata has no filter" do
    column = { "key" => "name", "label" => "Name" }
    table_state = { "visible_columns" => [column] }
    record = double("record", name: "Alice")

    html = helper.render(
      partial: "rails_table_preferences/resource_table",
      locals: {
        records: [record],
        model: double("model"),
        table_key: "users",
        name: "default",
        settings: {},
        columns: [column],
        table_state: table_state,
        profile: nil,
        caption: nil,
        options: { render_editor: false }
      }
    )

    expect(html).to include('data-rails-table-preferences-column-key="name"')
    expect(html).not_to include("data-rails-table-preferences-filter-type")
  end

  it "uses the same filter type data hooks in tree resource table row cells" do
    column = { "key" => "name", "label" => "Name", "filter" => { "type" => "text" } }
    item = double("item", name: "Alice")

    html = helper.render(
      partial: "rails_table_preferences/tree_resource_table_row",
      locals: {
        item: item,
        table_state: { "visible_columns" => [column] }
      }
    )

    expect(html).to include('data-rails-table-preferences-column-key="name"')
    expect(html).to include('data-rails-table-preferences-filter-type="text"')
  end
end
