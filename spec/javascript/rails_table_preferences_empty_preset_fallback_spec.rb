# frozen_string_literal: true

RSpec.describe "rails_table_preferences controller empty preset fallback" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:controller_source) { File.read(File.join(repo_root, "app/javascript/controllers/rails_table_preferences_controller.js")) }
  let(:docs_source) { File.read(File.join(repo_root, "docs/preset_empty_list_fallback.md")) }

  it "keeps the empty collection fallback tied to the current preset" do
    expect(controller_source).to include(
      "const presets = this.presets.length ? this.presets : [{ name: this.currentPresetName, default: false, editable: true }]"
    )
    expect(controller_source).to include("this.presetSelectTarget.value = this.currentPresetName")
  end

  it "keeps load failure status separate from the empty-list fallback" do
    expect(controller_source).to include("errorLabel: this.loadingFailedStatusLabelValue")
    expect(docs_source).to include("Empty collection: the request succeeded")
    expect(docs_source).to include("Load/auth/table-key failure")
  end
end
