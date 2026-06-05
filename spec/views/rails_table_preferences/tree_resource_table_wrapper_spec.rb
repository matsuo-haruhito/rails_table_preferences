# frozen_string_literal: true

RSpec.describe "rails_table_preferences/_tree_resource_table", type: :view do
  let(:columns) { [{ "key" => "name", "label" => "Name" }] }
  let(:table_state) { { "visible_columns" => columns } }

  before do
    stub_const("TreeView", Module.new)
    stub_const("TreeView::Tree", tree_class)
    stub_const("TreeView::UiConfigBuilder", ui_config_builder_class)
    stub_const("TreeView::RenderState", render_state_class)

    allow(view).to receive(:table_preferences_editor).and_return(%(<section id="table-preferences-editor"></section>).html_safe)
    allow(view).to receive(:tree_view_rows).and_return(%(<tr data-tree-row="true"><td>Name</td></tr>).html_safe)
  end

  it "wraps only the tree table when scroll_wrapper is enabled" do
    render_tree_resource_table(
      records: [],
      caption: "Projects",
      scroll_wrapper: true,
      wrapper_options: {
        class: "projects-table-scroll",
        data: { role: "tree-scroll" },
        aria: { label: "Scrollable projects table" }
      },
      options: {
        id: "projects-table",
        class: "projects-table",
        data: { turbo_frame: "projects-frame" },
        aria: { label: "Projects tree" },
        render_editor: false
      }
    )

    page = Capybara.string(rendered)
    wrapper = page.find(".rails-table-preferences-resource-table-scroll.projects-table-scroll")
    table = wrapper.find("table#projects-table")

    expect(wrapper[:"data-role"]).to eq("tree-scroll")
    expect(wrapper[:"aria-label"]).to eq("Scrollable projects table")
    expect(table[:class]).to include("tree-view-table")
    expect(table[:class]).to include("rails-table-preferences-tree-resource-table")
    expect(table[:class]).to include("projects-table")
    expect(table[:"data-turbo-frame"]).to eq("projects-frame")
    expect(table[:"aria-label"]).to eq("Projects tree")
    expect(table).to have_css("caption", text: "Projects")
    expect(table).to have_css(".rails-table-preferences-resource-table__empty-cell", text: "No records to display")
  end

  it "keeps table markup unwrapped by default" do
    render_tree_resource_table(
      records: [],
      scroll_wrapper: false,
      wrapper_options: { class: "unused-wrapper" },
      options: { id: "projects-table", class: "projects-table", render_editor: false }
    )

    page = Capybara.string(rendered)

    expect(page).to have_no_css(".rails-table-preferences-resource-table-scroll")
    expect(page).to have_css("table#projects-table.tree-view-table.rails-table-preferences-tree-resource-table.projects-table")
  end

  it "does not include the default editor inside the scroll wrapper" do
    render_tree_resource_table(
      records: [],
      scroll_wrapper: true,
      wrapper_options: { class: "projects-table-scroll" },
      options: { id: "projects-table" }
    )

    expect(rendered.index('id="table-preferences-editor"')).to be < rendered.index("rails-table-preferences-resource-table-scroll")
  end

  def render_tree_resource_table(records:, scroll_wrapper:, wrapper_options:, options:, caption: nil)
    render partial: "rails_table_preferences/tree_resource_table", locals: {
      records: records,
      model: Class.new,
      table_key: "projects_tree",
      parent_id_method: :parent_id,
      name: "default",
      settings: {},
      columns: columns,
      table_state: table_state,
      profile: nil,
      caption: caption,
      scroll_wrapper: scroll_wrapper,
      wrapper_options: wrapper_options,
      options: options
    }
  end

  def tree_class
    Class.new do
      attr_reader :root_items

      def initialize(records:, parent_id_method:)
        @root_items = records
      end
    end
  end

  def ui_config_builder_class
    Class.new do
      def initialize(context:, node_prefix:); end

      def build_static
        Object.new
      end
    end
  end

  def render_state_class
    Class.new do
      def initialize(tree:, root_items:, row_partial:, ui_config:, row_locals:); end
    end
  end
end
