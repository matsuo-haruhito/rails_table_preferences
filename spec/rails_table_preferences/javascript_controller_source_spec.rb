# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rails_table_preferences JavaScript controller source" do
  subject(:controller_source) do
    File.read(File.expand_path("../../app/javascript/controllers/rails_table_preferences_controller.js", __dir__))
  end

  it "creates an owner preset instead of patching a read-only preset" do
    expect(controller_source).to include("if (!this.currentPreferenceEditable) return this.createPresetFromEditor()")
    expect(controller_source).to include("method: \"POST\"")
    expect(controller_source).to include("method: \"PATCH\"")
  end

  it "uses the preset name input as the read-only owner copy name" do
    expect(controller_source).to include("body: JSON.stringify({ name: this.currentPresetName, settings: this.settingsValue, default: this.defaultPresetChecked })")
    expect(controller_source).to include("this.setPresetNameInput(payload.name)")
  end

  it "keeps the read-only state editable only after the created owner payload is applied" do
    expect(controller_source).to include("this.currentPreferenceEditable = payload.editable !== false")
    expect(controller_source).to include("await this.refreshPresetOptions()")
    expect(controller_source).to include("button.dataset.railsTablePreferencesNonEditableFallback = editable ? \"false\" : \"true\"")
  end
end
