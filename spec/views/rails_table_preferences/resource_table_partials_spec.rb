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

  it "keeps the default flat resource table empty copy" do
    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(options: { render_editor: false })

    expect(rendered).to include("No records to display")
  end

  it "renders a custom flat resource table empty message" do
    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(
      options: { render_editor: false, empty_message: "Change the search filters" }
    )

    expect(rendered).to include("Change the search filters")
    expect(rendered).not_to include("empty_message=")
  end

  it "escapes flat resource table empty messages as plain text" do
    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(
      options: { render_editor: false, empty_message: "<strong>No users</strong>" }
    )

    expect(rendered).to include("&lt;strong&gt;No users&lt;/strong&gt;")
    expect(rendered).not_to include("<strong>No users</strong>")
  end

  it "renders a valid empty row colspan when no flat resource table columns are visible" do
    all_hidden_columns = [
      {
        "key" => "name",
        "label" => "Name",
        "visible" => false,
        "pinned" => false
      }
    ]

    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(
      columns: all_hidden_columns,
      table_state: { "visible_columns" => [] },
      options: { render_editor: false }
    )

    expect(rendered).to include("rails-table-preferences-resource-table__empty-cell")
    expect(rendered).to include("colspan=\"1\"")
    expect(rendered).not_to include("colspan=\"0\"")
  end

  it "keeps the flat resource table empty row colspan aligned with visible columns" do
    visible_columns = [
      {
        "key" => "name",
        "label" => "Name",
        "visible" => true,
        "pinned" => false
      },
      {
        "key" => "email",
        "label" => "Email",
        "visible" => true,
        "pinned" => false
      }
    ]

    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(
      columns: visible_columns,
      table_state: { "visible_columns" => visible_columns },
      options: { render_editor: false }
    )

    expect(rendered).to include("colspan=\"2\"")
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

  it "renders a custom tree resource table empty message" do
    stub_tree_view_for_partial
    view.define_singleton_method(:tree_view_rows) { |_render_state| "".html_safe }

    render partial: "rails_table_preferences/tree_resource_table", locals: base_locals.merge(
      parent_id_method: :parent_id,
      options: { render_editor: false, empty_message: "No matching tree nodes" }
    )

    expect(rendered).to include("No matching tree nodes")
    expect(rendered).not_to include("empty_message=")
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
