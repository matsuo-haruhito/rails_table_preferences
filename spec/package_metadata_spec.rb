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

  it "publishes stable JavaScript entrypoints and declarations for bundlers" do
    expect(package_metadata.fetch("exports")).to eq(
      "." => {
        "types" => "./app/javascript/rails_table_preferences/index.d.ts",
        "default" => "./app/javascript/rails_table_preferences/index.js"
      },
      "./controller" => {
        "types" => "./app/javascript/rails_table_preferences/controller.d.ts",
        "default" => "./app/javascript/rails_table_preferences/preset_select_recovery.js"
      }
    )
  end

  it "keeps documented JavaScript import specifiers aligned with package exports" do
    exports = package_metadata.fetch("exports")

    expect(exports.keys).to contain_exactly(".", "./controller")
    expect(javascript_entrypoints_doc).to include('from "rails_table_preferences"')
    expect(javascript_entrypoints_doc).to include('from "rails_table_preferences/controller"')
    expect(javascript_entrypoints_doc).to include("RailsTablePreferencesController")
    expect(package_metadata.fetch("types")).to eq(exports.fetch(".").fetch("types"))
  end
end
