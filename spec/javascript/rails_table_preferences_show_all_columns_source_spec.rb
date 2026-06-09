# frozen_string_literal: true

RSpec.describe "rails_table_preferences show all columns source" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:controller_source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }
  let(:editor_source) { File.read(File.join(repo_root, "app/views/rails_table_preferences/_editor.html.erb")) }

  it "keeps show all columns separate from reset while preserving filters and sorts" do
    expect(controller_source).to include("showAllColumns(event)")
    expect(controller_source).to include("if (this.busy) return")
    expect(controller_source).to include("columns: this.columnsFromSettings.map((column) => ({ ...column, visible: true }))")
    expect(controller_source).to include("filters: this.settingsValue?.filters || {}")
    expect(controller_source).to include("sorts: this.settingsValue?.sorts || []")
    expect(controller_source).to include("this.renderEditor()")
    expect(controller_source).to include("this.apply()")
    expect(editor_source).to include('data-action="rails-table-preferences#showAllColumns"')
    expect(editor_source).to include("show_all_columns_hint")
  end
end
