# frozen_string_literal: true

require "spec_helper"

RSpec.describe "package entrypoint smoke boundary" do
  let(:root) { File.expand_path("..", __dir__) }
  let(:demo_smoke_spec) { read_repo_file("spec/system/rails_table_preferences_demo_smoke_spec.rb") }
  let(:manual_qa) { read_repo_file("docs/manual_qa.md") }
  let(:demo_doc) { read_repo_file("docs/demo.md") }

  it "keeps the generated demo browser smoke scoped to the copied/base controller" do
    expect(demo_smoke_spec).to include(
      "app/javascript/controllers/rails_table_preferences_controller.js",
      "CONTROLLER_SOURCE",
      "Rails Table Preferences Demo Smoke"
    )
    expect(demo_smoke_spec).not_to include("app/javascript/rails_table_preferences/controller.js")
  end

  it "keeps package-entrypoint-only affordances routed to manual/source-level QA" do
    expect(manual_qa).to include(
      "If the screen uses the package entrypoint, search for one editor row and use the row up/down controls once",
      "if it uses a copied controller, record that the numeric order input remains the keyboard-friendly fallback instead",
      "On package entrypoint screens, use the editor row search to find a column by label, key, or group text",
      "On copied-controller screens, confirm those package entrypoint-only search and row move controls are not assumed to exist"
    )
    expect(demo_doc).to include(
      "Current automated browser/system smoke covers:",
      "hide column and apply",
      "Good next automated checks are:"
    )
  end

  def read_repo_file(path)
    File.read(File.join(root, path))
  end
end
