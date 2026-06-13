# frozen_string_literal: true

require "json"
require "spec_helper"

RSpec.describe "package entrypoint preset selector search source" do
  let(:package_controller_path) do
    File.expand_path("../app/javascript/rails_table_preferences/controller.js", __dir__)
  end

  let(:base_controller_source_path) do
    File.expand_path("../app/javascript/controllers/rails_table_preferences_controller.js", __dir__)
  end

  let(:index_source_path) do
    File.expand_path("../app/javascript/rails_table_preferences/index.js", __dir__)
  end

  let(:package_json_path) do
    File.expand_path("../package.json", __dir__)
  end

  let(:package_controller) { File.read(package_controller_path) }
  let(:base_controller_source) { File.read(base_controller_source_path) }
  let(:index_source) { File.read(index_source_path) }
  let(:package_json) { JSON.parse(File.read(package_json_path)) }

  it "keeps the public package entrypoints on the recovery controller" do
    expect(index_source).to include('import RailsTablePreferencesController from "./preset_select_recovery.js"')
    expect(index_source).to include("export default RailsTablePreferencesController")
    expect(index_source).to include("export { RailsTablePreferencesController }")
    expect(package_json.dig("exports", "./controller", "default")).to eq("./app/javascript/rails_table_preferences/preset_select_recovery.js")
  end

  it "keeps preset selector search package-entrypoint only" do
    expect(package_controller).to include("presetSearchLabel: { type: String")
    expect(package_controller).to include("ensurePresetSearchControl()")
    expect(package_controller).to include("presetSearchText(preset)")
    expect(base_controller_source).not_to include("ensurePresetSearchControl")
    expect(base_controller_source).not_to include("presetSearchText")
  end

  it "filters by preset name and scope text without changing option metadata" do
    expect(package_controller).to include("const allPresets = this.presets.length ? this.presets : [{ name: this.currentPresetName, default: false, editable: true }]")
    expect(package_controller).to include("const visiblePresets = query ? allPresets.filter((preset) => this.presetMatchesSearch(preset, query)) : allPresets")
    expect(package_controller).to include("return [preset.name || \"default\", scopeLabel, scopeType]")
    expect(package_controller).to include("this.groupPresetsForSelect(presets)")
    expect(package_controller).to include("this.buildPresetOption(preset)")
    expect(base_controller_source).to include("option.dataset.default = preset.default === true ? \"true\" : \"false\"")
    expect(base_controller_source).to include("option.dataset.editable = preset.editable === false ? \"false\" : \"true\"")
    expect(base_controller_source).to include("option.dataset.scopeType = scopeType")
    expect(base_controller_source).to include("option.dataset.scopeKey = preset.scope_key || \"\"")
  end

  it "keeps no-match search from selecting or loading an accidental preset" do
    expect(package_controller).to include("if (visiblePresets.length > 0) this.appendPresetOptions(visiblePresets)")
    expect(package_controller).to include("this.presetSelectTarget.disabled = this.busy || (enabled && Boolean(query) && visibleCount === 0)")
    expect(package_controller).to include("if (this.presetSearchEmptyMessage) this.presetSearchEmptyMessage.hidden = !enabled || !query || visibleCount > 0")
    expect(package_controller).not_to include("this.applyPreferencePayload(")
  end

  it "does not show another visible preset as selected when the current preset is filtered out" do
    expect(package_controller).to include("const currentPresetVisible = visiblePresets.some((preset) => (preset.name || \"default\") === this.currentPresetName)")
    expect(package_controller).to include("this.presetSelectTarget.value = this.currentPresetName")
    expect(package_controller).to include("this.presetSelectTarget.selectedIndex = -1")
  end
end
