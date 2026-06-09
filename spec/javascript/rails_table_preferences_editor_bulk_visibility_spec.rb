# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rails_table_preferences editor bulk visibility controls" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:package_controller) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }
  let(:editor_partial) { File.read(File.join(repo_root, "app/views/rails_table_preferences/_editor.html.erb")) }

  it "wires show and hide actions to existing visible checkboxes" do
    expect(package_controller).to include("showAllEditorColumns(event)")
    expect(package_controller).to include("hideAllEditorColumns(event)")
    expect(package_controller).to include("setEditorColumnVisibility(event, true)")
    expect(package_controller).to include("setEditorColumnVisibility(event, false)")
    expect(package_controller).to include("visibleInput.checked = visible === true")
    expect(package_controller).to include("this.clearSuccessfulStatus()")

    expect(editor_partial).to include("rails-table-preferences#showAllEditorColumns")
    expect(editor_partial).to include("rails-table-preferences#hideAllEditorColumns")
    expect(editor_partial).to include("visibility_bulk_hint")
    expect(editor_partial).to include("visibility_bulk_action_group")
  end
end
