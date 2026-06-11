# frozen_string_literal: true

require "spec_helper"

RSpec.describe "preset selector fallback source" do
  let(:controller_source_path) do
    File.expand_path("../../app/javascript/controllers/rails_table_preferences_controller.js", __dir__)
  end

  let(:controller_source) { File.read(controller_source_path) }

  it "keeps the first-run preset selector populated by the current name" do
    expect(controller_source).to include(
      "const presets = this.presets.length ? this.presets : [{ name: this.currentPresetName, default: false, editable: true }]"
    )
    expect(controller_source).to include("this.presetSelectTarget.value = this.currentPresetName")
  end
end
