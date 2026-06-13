# frozen_string_literal: true

require "json"
require "spec_helper"

RSpec.describe "preset select load recovery package entrypoint" do
  let(:root_path) { File.expand_path("../..", __dir__) }

  it "exports the recovery controller for package controller imports" do
    package_json = JSON.parse(File.read(File.join(root_path, "package.json")))

    expect(package_json.dig("exports", ".", "default")).to eq("./app/javascript/rails_table_preferences/index.js")
    expect(package_json.dig("exports", "./controller", "default")).to eq("./app/javascript/rails_table_preferences/preset_select_recovery.js")
  end

  it "restores the preset selector to the applied preset after a failed load" do
    source = File.read(File.join(root_path, "app/javascript/rails_table_preferences/preset_select_recovery.js"))

    expect(source).to include("const appliedPresetName = this.nameValue || this.currentPresetName")
    expect(source).to include("this.statusState !== \"success\"")
    expect(source).to include("this.presetSelectTarget.value = name || \"default\"")
    expect(source).to include("this.syncDeletePresetButtonContext()")
  end
end
