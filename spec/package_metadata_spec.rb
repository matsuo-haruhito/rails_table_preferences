# frozen_string_literal: true

require "json"
require "spec_helper"

RSpec.describe "rails_table_preferences package metadata" do
  subject(:package_metadata) { JSON.parse(File.read(package_json_path)) }

  let(:repo_root) do
    File.expand_path("..", __dir__)
  end

  let(:package_json_path) do
    File.join(repo_root, "package.json")
  end

  let(:readme) do
    File.read(File.join(repo_root, "README.md"))
  end

  let(:javascript_entrypoints_doc) do
    File.read(File.join(repo_root, "docs/javascript_entrypoints.md"))
  end

  it "publishes the documented package name, module type, and root declaration" do
    expect(package_metadata).to include(
      "name" => "rails_table_preferences",
      "type" => "module",
      "types" => "./app/javascript/rails_table_preferences/index.d.ts"
    )
  end

  it "publishes stable JavaScript entrypoints, declarations, and stylesheet export for bundlers" do
    expect(package_metadata.fetch("exports")).to eq(
      "." => {
        "types" => "./app/javascript/rails_table_preferences/index.d.ts",
        "default" => "./app/javascript/rails_table_preferences/index.js"
      },
      "./controller" => {
        "types" => "./app/javascript/rails_table_preferences/controller.d.ts",
        "default" => "./app/javascript/rails_table_preferences/preset_select_recovery.js"
      },
      "./styles.css" => "./app/assets/stylesheets/rails_table_preferences.css"
    )
  end

  it "keeps documented JavaScript and stylesheet import specifiers aligned with package exports" do
    exports = package_metadata.fetch("exports")

    expect(exports.keys).to contain_exactly(".", "./controller", "./styles.css")
    expect(javascript_entrypoints_doc).to include('from "rails_table_preferences"')
    expect(javascript_entrypoints_doc).to include('from "rails_table_preferences/controller"')
    expect(javascript_entrypoints_doc).to include('import "rails_table_preferences/styles.css"')
    expect(javascript_entrypoints_doc).to include("RailsTablePreferencesController")
    expect(package_metadata.fetch("types")).to eq(exports.fetch(".").fetch("types"))
  end

  it "keeps documented manual controller aliases aligned with the package export target" do
    controller_entrypoint = package_metadata.fetch("exports").fetch("./controller").fetch("default")
    controller_alias_target = controller_entrypoint.delete_prefix("./app/javascript/")
    stale_controller_alias = 'gemJavaScriptPath("rails_table_preferences", "rails_table_preferences/controller.js")'

    expect(controller_alias_target).to eq("rails_table_preferences/preset_select_recovery.js")
    expect(readme).to include(%(gemJavaScriptPath("rails_table_preferences", "#{controller_alias_target}")))
    expect(javascript_entrypoints_doc).to include(%(gemJavaScriptPath("rails_table_preferences", "#{controller_alias_target}")))
    expect(readme).not_to include(stale_controller_alias)
    expect(javascript_entrypoints_doc).not_to include(stale_controller_alias)
  end
end
