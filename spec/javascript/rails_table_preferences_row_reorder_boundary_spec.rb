# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rails_table_preferences row reorder entrypoint boundary" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:base_controller_source) { File.read(File.join(repo_root, "app/javascript/controllers/rails_table_preferences_controller.js")) }
  let(:package_controller_source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }
  let(:install_paths_doc) { File.read(File.join(repo_root, "docs/install_paths.md")) }
  let(:entrypoint_affordances_doc) { File.read(File.join(repo_root, "docs/editor_entrypoint_affordances.md")) }

  it "keeps row move controls package-entrypoint-only" do
    expect(package_controller_source).to include("buildEditorMoveControls")
    expect(package_controller_source).to include("moveEditorRow")
    expect(package_controller_source).to include("data-rails-table-preferences-move-direction")
    expect(package_controller_source).to include("moveUpLabel")
    expect(package_controller_source).to include("moveDownLabel")

    expect(base_controller_source).not_to include("buildEditorMoveControls")
    expect(base_controller_source).not_to include("moveEditorRow")
    expect(base_controller_source).not_to include("data-rails-table-preferences-move-direction")
    expect(base_controller_source).not_to include("moveUpLabel")
    expect(base_controller_source).not_to include("moveDownLabel")
  end

  it "documents numeric order inputs as the copied controller fallback" do
    expect(install_paths_doc).to include("The copied controller keeps native row drag/drop and numeric order inputs as its keyboard-friendly fallback")
    expect(install_paths_doc).to include("The package entrypoint adds column search plus row up/down buttons")
    expect(entrypoint_affordances_doc).to include("The copied/base controller does not render these row move buttons")
    expect(entrypoint_affordances_doc).to include("the keyboard-friendly reorder fallback remains the numeric order input plus the bundled `適用` action")
  end
end
