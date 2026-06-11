# frozen_string_literal: true

require "spec_helper"

RSpec.describe "package entrypoint preset selector search source" do
  let(:preset_search_controller_path) do
    File.expand_path("../app/javascript/rails_table_preferences/controller_with_preset_search.js", __dir__)
  end

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

  let(:preset_search_controller) { File.read(preset_search_controller_path) }
  let(:package_controller) { File.read(package_controller_path) }
  let(:base_controller_source) { File.read(base_controller_source_path) }
  let(:index_source) { File.read(index_source_path) }
  let(:package_json) { File.read(package_json_path) }

  it "routes package entrypoints through the preset search wrapper" do
    expect(index_source).to include('export { default } from "./controller_with_preset_search"')
    expect(index_source).to include('export { default as RailsTablePreferencesController } from "./controller_with_preset_search"')
    expect(package_json).to include('"default": "./app/javascript/rails_table_preferences/controller_with_preset_search.js"')
    expect(preset_search_controller).to include('import PackageController from "./controller"')
  end

  it "keeps preset selector search package-entrypoint only" do
    expect(preset_search_controller).to include("presetSearchLabel: { type: String")
    expect(preset_search_controller).to include("ensurePresetSearchControl()")
    expect(preset_search_controller).to include("presetSearchText(preset)")
    expect(package_controller).not_to include("ensurePresetSearchControl")
    expect(base_controller_source).not_to include("ensurePresetSearchControl")
    expect(base_controller_source).not_to include("presetSearchText")
  end

  it "filters by preset name and scope text without changing payload shape" do
    expect(preset_search_controller).to include("const allPresets = this.presets.length ? this.presets : [{ name: this.currentPresetName, default: false, editable: true }]")
    expect(preset_search_controller).to include("const visiblePresets = query ? allPresets.filter((preset) => this.presetMatchesSearch(preset, query)) : allPresets")
    expect(preset_search_controller).to include("return [preset.name || \"default\", scopeLabel, scopeType]")
    expect(preset_search_controller).to include("this.groupPresetsForSelect(presets)")
    expect(preset_search_controller).to include("this.buildPresetOption(preset)")
    expect(base_controller_source).to include("option.dataset.default = preset.default === true ? \"true\" : \"false\"")
    expect(base_controller_source).to include("option.dataset.editable = preset.editable === false ? \"false\" : \"true\"")
    expect(base_controller_source).to include("option.dataset.scopeType = scopeType")
    expect(base_controller_source).to include("option.dataset.scopeKey = preset.scope_key || \"\"")
  end

  it "keeps no-match search from selecting or loading an accidental preset" do
    expect(preset_search_controller).to include("if (visiblePresets.length > 0) this.appendPresetOptions(visiblePresets)")
    expect(preset_search_controller).to include("this.presetSelectTarget.disabled = this.busy || (enabled && Boolean(query) && visibleCount === 0)")
    expect(preset_search_controller).to include("if (this.presetSearchEmptyMessage) this.presetSearchEmptyMessage.hidden = !enabled || !query || visibleCount > 0")
    expect(preset_search_controller).not_to include("this.selectPreset(")
    expect(preset_search_controller).not_to include("this.applyPreferencePayload(")
  end
end
