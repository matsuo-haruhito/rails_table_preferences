# frozen_string_literal: true

require "spec_helper"

RSpec.describe "package entrypoint lifecycle error source" do
  let(:controller_source_path) do
    File.expand_path("../app/javascript/rails_table_preferences/controller.js", __dir__)
  end

  let(:base_controller_source_path) do
    File.expand_path("../app/javascript/controllers/rails_table_preferences_controller.js", __dir__)
  end

  let(:controller_declaration_path) do
    File.expand_path("../app/javascript/rails_table_preferences/controller.d.ts", __dir__)
  end

  let(:index_declaration_path) do
    File.expand_path("../app/javascript/rails_table_preferences/index.d.ts", __dir__)
  end

  let(:javascript_controller_doc_path) do
    File.expand_path("../docs/javascript_controller.md", __dir__)
  end

  let(:controller_source) { File.read(controller_source_path) }
  let(:base_controller_source) { File.read(base_controller_source_path) }
  let(:controller_declaration) { File.read(controller_declaration_path) }
  let(:index_declaration) { File.read(index_declaration_path) }
  let(:javascript_controller_doc) { File.read(javascript_controller_doc_path) }

  it "keeps named preference operations attached to stable error actions" do
    expected_action_sources = {
      "save" => "this.withPreferenceAction(\"save\", () => super.save(event))",
      "create" => "this.withPreferenceAction(\"create\", () => super.createPresetFromEditor(event))",
      "load" => "this.withPreferenceAction(\"load\", () => super.selectPreset(event))",
      "delete" => "this.withPreferenceAction(\"delete\", async () => {",
      "load-presets" => "this.withPreferenceAction(\"load-presets\", () => super.refreshPresetOptionsOnConnect())"
    }

    expected_action_sources.each_value do |source_signal|
      expect(controller_source).to include(source_signal)
    end

    expect(controller_source).to include("action: this.currentPreferenceAction || \"operation\"")
    expect(controller_source).to include("message: message || this.operationFailedStatusLabelValue")
  end

  it "keeps lifecycle error events package-entrypoint only" do
    expect(controller_source).to include("this.dispatchPreferenceEvent(\"error\", {")
    expect(base_controller_source).not_to include("dispatchPreferenceEvent(\"error\"")
    expect(base_controller_source).not_to include("withPreferenceAction")
  end

  it "keeps declaration and docs aligned with the error action boundary" do
    expect(controller_declaration).to include(
      "export type RailsTablePreferencesErrorAction = RailsTablePreferencesSuccessAction | \"load-presets\" | \"operation\""
    )
    expect(index_declaration).to include("RailsTablePreferencesErrorAction")

    %w[load-presets load save create delete operation].each do |action|
      expect(javascript_controller_doc).to include(action)
    end

    expect(javascript_controller_doc).to include("display-safe `message`")
    expect(javascript_controller_doc).to include("does not expose DOM nodes or the raw `Error` object")
    expect(javascript_controller_doc).to include("update this list and the source-level lifecycle event specs")
  end
end
