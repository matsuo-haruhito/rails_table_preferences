# frozen_string_literal: true

require "json"
require "spec_helper"

RSpec.describe "rails_table_preferences package metadata" do
  subject(:package_metadata) { JSON.parse(File.read(package_json_path)) }

  let(:package_json_path) do
    File.expand_path("../package.json", __dir__)
  end

  it "publishes the documented package name and module type" do
    expect(package_metadata).to include(
      "name" => "rails_table_preferences",
      "type" => "module"
    )
  end

  it "publishes stable JavaScript entrypoints for bundlers" do
    expect(package_metadata.fetch("exports")).to eq(
      "." => "./app/javascript/rails_table_preferences/index.js",
      "./controller" => "./app/javascript/rails_table_preferences/controller.js"
    )
  end
end
