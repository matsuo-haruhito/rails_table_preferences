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

  it "passes editor_html_options to the resource table editor only" do
    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(
      options: {
        id: "users-table",
        data: { turbo_frame: "users-frame" },
        editor_html_options: {
          id: "users-editor",
          class: "users-editor",
          data: { placement: "toolbar" },
          aria: { label: "User table settings" }
        }
      }
    )

    table_tag = rendered[/<table[^>]*>/]

    expect(rendered).to include("id=\"users-editor\"")
    expect(rendered).to include("rails-table-preferences-editor users-editor")
    expect(rendered).to include("data-placement=\"toolbar\"")
    expect(rendered).to include("aria-label=\"User table settings\"")
    expect(table_tag).to include("id=\"users-table\"")
    expect(table_tag).to include("data-turbo-frame=\"users-frame\"")
    expect(table_tag).not_to include("users-editor")
    expect(table_tag).not_to include("data-placement")
    expect(rendered).not_to include("editor_html_options")
  end

  it "renders only the resource table surface when render_editor is false" do
    render partial: "rails_table_preferences/resource_table", locals: base_locals.merge(
      options: {
        render_editor: false,
        id: "users-table",
        data: { turbo_frame: "users-frame" },
        editor_html_options: { data: { placement: "toolbar" } }
      }
    )

    expect(rendered).not_to include("rails-table-preferences-editor")
    expect(rendered).to include("id=\"users-table\"")
    expect(rendered).to include("data-turbo-frame=\"users-frame\"")
    expect(rendered).to include("data-rails-table-preferences-table-key-value=\"users\"")
    expect(rendered).not_to include("render_editor")
    expect(rendered).not_to include("editor_html_options")
    expect(rendered).not_to include("data-placement")
  end

  it "passes editor_html_options to the tree resource table editor only" do
    stub_tree_view_for_partial
    view.define_singleton_method(:tree_view_rows) { |_render_state| "".html_safe }

    render partial: "rails_table_preferences/tree_resource_table", locals: base_locals.merge(
      parent_id_method: :parent_id,
      options: {
        class: "users-tree",
        editor_html_options: {
          id: "users-tree-editor",
          class: "users-tree-editor",
          data: { placement: "drawer" }
        }
      }
    )

    table_tag = rendered[/<table[^>]*>/]

    expect(rendered).to include("id=\"users-tree-editor\"")
    expect(rendered).to include("rails-table-preferences-editor users-tree-editor")
    expect(rendered).to include("data-placement=\"drawer\"")
    expect(table_tag).to include("tree-view-table rails-table-preferences-tree-resource-table users-tree")
    expect(table_tag).not_to include("users-tree-editor")
    expect(table_tag).not_to include("data-placement")
    expect(rendered).not_to include("editor_html_options")
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
