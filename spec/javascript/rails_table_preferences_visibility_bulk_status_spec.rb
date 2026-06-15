# frozen_string_literal: true

require "spec_helper"

RSpec.describe "package entrypoint bulk visibility recovery status" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:controller_source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }
  let(:editor_partial_source) { File.read(File.join(repo_root, "app/views/rails_table_preferences/_editor.html.erb")) }
  let(:english_locale_source) { File.read(File.join(repo_root, "config/locales/en.yml")) }
  let(:japanese_locale_source) { File.read(File.join(repo_root, "config/locales/ja.yml")) }

  def source_between(source, start_marker, end_marker)
    start_index = source.index(start_marker)
    end_index = source.index(end_marker, start_index || 0)
    return "" unless start_index && end_index

    source[start_index...end_index]
  end

  it "passes localized hide-all and show-all status copy through the bundled editor root" do
    expect(editor_partial_source).to include("data-rails-table-preferences-visibility-bulk-hidden-status-label-value")
    expect(editor_partial_source).to include("rails_table_preferences.editor.visibility_bulk_hidden_status")
    expect(editor_partial_source).to include("data-rails-table-preferences-visibility-bulk-shown-status-label-value")
    expect(editor_partial_source).to include("rails_table_preferences.editor.visibility_bulk_shown_status")

    expect(english_locale_source).to include("visibility_bulk_hidden_status: All columns are hidden. Use Show all columns to restore them.")
    expect(english_locale_source).to include("visibility_bulk_shown_status: All columns are visible again.")
    expect(japanese_locale_source).to include("visibility_bulk_hidden_status: すべての列を非表示にしました。全列表示で戻せます。")
    expect(japanese_locale_source).to include("visibility_bulk_shown_status: すべての列を表示しました。")
  end

  it "keeps hide-all allowed and announces Show all columns as the recovery path" do
    expect(controller_source).to include('visibilityBulkHiddenStatusLabel: { type: String, default: "すべての列を非表示にしました。全列表示で戻せます。" }')
    expect(controller_source).to include('visibilityBulkShownStatusLabel: { type: String, default: "すべての列を表示しました。" }')

    method_source = source_between(controller_source, "  setEditorColumnVisibility(event, visible) {", "  buildEditorMoveControls() {")
    expect(method_source).to include("if (this.busy) return")
    expect(method_source).to include("visibleInput.checked = visible === true")
    expect(method_source).to include("this.setStatus(visible ? this.visibilityBulkShownStatusLabelValue : this.visibilityBulkHiddenStatusLabelValue, \"success\")")
    expect(method_source).not_to include("throw")
    expect(method_source).not_to include("confirm")
  end
end
