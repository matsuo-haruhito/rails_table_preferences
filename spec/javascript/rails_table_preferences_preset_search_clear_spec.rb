# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rails_table_preferences preset search clear affordance" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/preset_select_recovery.js")) }

  it "keeps the clear affordance scoped to the package preset search surface" do
    expect(source).to include("presetSearchClearLabel: { type: String, default: \"検索をクリア\" }")
    expect(source).to include("button.dataset.railsTablePreferencesPresetSearchClear = \"true\"")
    expect(source).to include("button.addEventListener(\"click\", (event) => this.clearPresetSearchQuery(event))")
    expect(source).to include("this.presetSearchControl?.querySelector(\"[data-rails-table-preferences-preset-search-clear]\")")
  end

  it "only enables clearing when a preset search query is active and the editor is not busy" do
    expect(source).to include("const hasQuery = enabled && Boolean(query)")
    expect(source).to include("this.presetSearchClearButton.hidden = !hasQuery")
    expect(source).to include("this.presetSearchClearButton.disabled = this.busy || !hasQuery")
  end

  it "clears the query by re-rendering preset options without touching preset persistence" do
    clear_method = source[/clearPresetSearchQuery\(event\) \{.*?\n  \}/m]

    expect(clear_method).to include("if (event) event.preventDefault()")
    expect(clear_method).to include("if (this.busy) return")
    expect(clear_method).to include("input.value = \"\"")
    expect(clear_method).to include("this.renderPresetOptions()")
    expect(clear_method).not_to include("fetch(")
    expect(clear_method).not_to include("preferenceUrl")
    expect(clear_method).not_to include("settingsValue")
  end
end
