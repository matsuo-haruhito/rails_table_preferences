# frozen_string_literal: true

RSpec.describe "resource table rendering", type: :helper do
  before do
    RailsTablePreferences.configuration.unresolved_label_behavior = :humanize
  end

  def stub_tree_view_resource_table_dependencies
    stub_const("TreeView", Module.new)
    stub_const("TreeView::Tree", Class.new do
      attr_reader :root_items

      def initialize(records:, parent_id_method:)
        @root_items = records
      end
    end)
    stub_const("TreeView::UiConfigBuilder", Class.new do
      def initialize(context:, node_prefix:); end

      def build_static
        {}
      end
    end)
    stub_const("TreeView::RenderState", Class.new do
      def initialize(**); end
    end)
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

  it "keeps the default tree resource table markup unwrapped" do
    stub_tree_view_resource_table_dependencies

    html = helper.tree_resource_table_for(
      User.none,
      model: User,
      table_key: :users_tree,
      only: %i[name],
      class: "projects-tree",
      render_editor: false
    )

    expect(html).to include('class="tree-view-table rails-table-preferences-tree-resource-table projects-tree"')
    expect(html).to include('class="rails-table-preferences-resource-table__empty-cell" colspan="1"')
    expect(html).not_to include("rails-table-preferences-resource-table-scroll")
  end

  it "renders an optional tree resource scroll wrapper without moving table options" do
    stub_tree_view_resource_table_dependencies

    html = helper.tree_resource_table_for(
      User.none,
      model: User,
      table_key: :users_tree,
      only: %i[name],
      class: "projects-tree",
      data: { turbo_frame: "projects-frame" },
      scroll_wrapper: true,
      wrapper_options: {
        class: "projects-scroll",
        data: { role: "tree-resource-scroll" },
        aria: { label: "Scrollable projects tree" }
      },
      render_editor: false
    )

    expect(html).to include('class="rails-table-preferences-resource-table-scroll projects-scroll"')
    expect(html).to include('data-role="tree-resource-scroll"')
    expect(html).to include('aria-label="Scrollable projects tree"')
    expect(html).to include('class="tree-view-table rails-table-preferences-tree-resource-table projects-tree"')
    expect(html).to include('data-turbo-frame="projects-frame"')
  end

  it "keeps the tree resource all-hidden fallback inside the optional wrapper" do
    stub_tree_view_resource_table_dependencies

    item = double("item", id: 1, parent_id: nil, name: "Root")

    html = helper.render(
      partial: "rails_table_preferences/tree_resource_table",
      locals: {
        records: [item],
        model: User,
        table_key: "users_tree",
        parent_id_method: :parent_id,
        name: "default",
        settings: {},
        columns: [{ "key" => "name", "label" => "Name" }],
        table_state: { "visible_columns" => [] },
        profile: nil,
        caption: nil,
        scroll_wrapper: true,
        wrapper_options: { class: "projects-scroll" },
        options: { render_editor: false }
      }
    )

    expect(html).to include('class="rails-table-preferences-resource-table-scroll projects-scroll"')
    expect(html).to include("All columns are hidden")
    expect(html).to include('class="rails-table-preferences-resource-table__hidden-columns-cell" colspan="1"')
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
        scroll_wrapper: false,
        wrapper_options: {},
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
