# frozen_string_literal: true

RSpec.describe "rails_table_preferences resource table partials", type: :view do
  let(:columns) do
    [
      {
        "key" => "name",
        "label" => "Name",
        "visible" => true,
        "pinned" => false
      }
    ]
  end

  let(:table_state) { { "visible_columns" => columns } }

  let(:base_locals) do
    {
      records: User.none,
      model: User,
      table_key: "users",
      name: "default",
      settings: {},
      columns: columns,
      table_state: table_state,
      profile: nil
    }
  end

  it "renders the resource table editor by default" do
    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(options: {})

    expect(rendered).to include("rails-table-preferences-editor")
    expect(rendered).to include("rails-table-preferences-resource-table")
    expect(rendered).to include("data-rails-table-preferences-table-key-value=\"users\"")
  end

  it "renders only the resource table surface when render_editor is false" do
    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(
      options: {
        render_editor: false,
        id: "users-table",
        data: { turbo_frame: "users-frame" }
      }
    )

    expect(rendered).not_to include("rails-table-preferences-editor")
    expect(rendered).to include("id=\"users-table\"")
    expect(rendered).to include("data-turbo-frame=\"users-frame\"")
    expect(rendered).to include("data-rails-table-preferences-table-key-value=\"users\"")
    expect(rendered).not_to include("render_editor")
  end

  it "renders only the tree resource table surface when render_editor is false" do
    stub_tree_view_for_partial
    view.define_singleton_method(:tree_view_rows) { |_render_state| "".html_safe }

    render partial: "rails_table_preferences/tree_resource_table", locals: base_locals.merge(
      parent_id_method: :parent_id,
      options: { render_editor: false }
    )

    expect(rendered).not_to include("rails-table-preferences-editor")
    expect(rendered).to include("tree-view-table")
    expect(rendered).to include("rails-table-preferences-tree-resource-table")
    expect(rendered).to include("data-rails-table-preferences-table-key-value=\"users\"")
    expect(rendered).not_to include("render_editor")
  end

  it "renders a table-specific empty message for empty resource table records" do
    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(
      options: {
        render_editor: false,
        empty_message: "No users match this search"
      }
    )

    expect(rendered).to include("No users match this search")
    expect(rendered).not_to include("No records to display")
    expect(rendered).not_to include("empty-message")
  end

  it "keeps the existing empty message fallback when no resource table empty message is provided" do
    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(
      options: { render_editor: false }
    )

    expect(rendered).to include("No records to display")
  end

  it "escapes resource table empty messages as plain text" do
    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(
      options: {
        render_editor: false,
        empty_message: "<strong>No users</strong>"
      }
    )

    expect(rendered).to include("&lt;strong&gt;No users&lt;/strong&gt;")
    expect(rendered).not_to include("<strong>No users</strong>")
  end

  it "does not render the resource table empty message when records are present" do
    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(
      records: [User.new(name: "Alice")],
      options: {
        render_editor: false,
        empty_message: "No users match this search"
      }
    )

    expect(rendered).to include("Alice")
    expect(rendered).not_to include("No users match this search")
  end

  it "keeps resource table empty row colspan valid when every column is hidden" do
    hidden_columns = columns.map { |column| column.merge("visible" => false) }

    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(
      columns: hidden_columns,
      table_state: { "visible_columns" => [] },
      options: { render_editor: false }
    )

    expect(rendered).to include("rails-table-preferences-resource-table__empty-cell")
    expect(rendered).to include("colspan=\"1\"")
  end

  it "renders a flat resource table fallback row when records exist but every column is hidden" do
    hidden_columns = columns.map { |column| column.merge("visible" => false) }

    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(
      records: [double("record", name: "Alice")],
      columns: hidden_columns,
      table_state: { "visible_columns" => [] },
      options: { render_editor: false }
    )

    expect(rendered).to include("rails-table-preferences-resource-table__hidden-columns-cell")
    expect(rendered).to include("All columns are hidden")
    expect(rendered).to include("colspan=\"1\"")
    expect(rendered).not_to include("Alice")
  end

  it "keeps tree resource empty row colspan valid when every column is hidden" do
    stub_tree_view_for_partial
    hidden_columns = columns.map { |column| column.merge("visible" => false) }

    render partial: "rails_table_preferences/tree_resource_table", locals: base_locals.merge(
      columns: hidden_columns,
      table_state: { "visible_columns" => [] },
      parent_id_method: :parent_id,
      options: { render_editor: false }
    )

    expect(rendered).to include("rails-table-preferences-resource-table__empty-cell")
    expect(rendered).to include("colspan=\"1\"")
  end

  it "renders a tree resource table fallback row when records exist but every column is hidden" do
    stub_tree_view_for_partial
    hidden_columns = columns.map { |column| column.merge("visible" => false) }
    view.define_singleton_method(:tree_view_rows) do |_render_state|
      raise "tree rows should not render without visible columns"
    end

    render partial: "rails_table_preferences/tree_resource_table", locals: base_locals.merge(
      records: [double("record", name: "Alice")],
      columns: hidden_columns,
      table_state: { "visible_columns" => [] },
      parent_id_method: :parent_id,
      options: { render_editor: false }
    )

    expect(rendered).to include("rails-table-preferences-resource-table__hidden-columns-cell")
    expect(rendered).to include("All columns are hidden")
    expect(rendered).to include("colspan=\"1\"")
  end

  def stub_tree_view_for_partial
    stub_const("TreeView", Module.new) unless defined?(TreeView)

    stub_const("TreeView::Tree", Class.new do
      def initialize(records:, parent_id_method:)
      end

      def root_items
        []
      end
    end)

    stub_const("TreeView::UiConfigBuilder", Class.new do
      def initialize(context:, node_prefix:)
      end

      def build_static
        Object.new
      end
    end)

    stub_const("TreeView::RenderState", Class.new do
      def initialize(**)
      end
    end)
  end
end
