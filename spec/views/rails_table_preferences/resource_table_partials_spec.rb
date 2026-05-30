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
    render partial: "rails_table_preferences/tree_resource_table", locals: base_locals.merge(
      parent_id_method: :parent_id,
      options: { render_editor: false }
    )

    expect(rendered).not_to include("rails-table-preferences-editor")
    expect(rendered).to include("tree-view-table")
    expect(rendered).to include("rails-table-preferences-tree-resource-table")
    expect(rendered).to include("data-rails-table-preferences-table-key-value=\"users\"")
  end
end
