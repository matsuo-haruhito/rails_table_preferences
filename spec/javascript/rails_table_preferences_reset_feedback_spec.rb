# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rails_table_preferences reset feedback JavaScript contract" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:package_controller_source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }
  let(:editor_partial_source) { File.read(File.join(repo_root, "app/views/rails_table_preferences/_editor.html.erb")) }

  it "exposes reset result copy through the bundled editor root" do
    expect(editor_partial_source).to include("data-rails-table-preferences-reset-status-label-value")
    expect(editor_partial_source).to include("rails_table_preferences.editor.reset_status")
    expect(editor_partial_source).to include("テーブル初期設定に戻しました。")
  end

  it "announces reset completion and refreshes the reset button state" do
    expect(package_controller_source).to include("resetStatusLabel: { type: String, default: \"テーブル初期設定に戻しました。\" }")
    expect(package_controller_source).to include("this.setStatus(this.resetStatusLabelValue, \"success\")")
    expect(package_controller_source).to include("this.syncResetButtonState()")
    expect(package_controller_source).to include("this.dispatchPreferenceEvent(\"reset\", { action: \"reset\" })")
  end

  it "keeps the reset affordance disabled when the current editor state already matches defaults" do
    expect(package_controller_source).to include("syncResetButtonState()")
    expect(package_controller_source).to include("editorMatchesDefaultSettings()")
    expect(package_controller_source).to include("button.disabled = this.busy || this.editorMatchesDefaultSettings()")
    expect(package_controller_source).to include("this.normalizedSettingsFingerprint(this.settingsFromEditor())")
    expect(package_controller_source).to include("this.normalizedSettingsFingerprint(this.defaultSettings)")
  end
end
