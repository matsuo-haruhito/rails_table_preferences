# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rails_table_preferences resize auto-fit status feedback" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:package_controller_source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }
  let(:editor_partial_source) { File.read(File.join(repo_root, "app/views/rails_table_preferences/_editor.html.erb")) }
  let(:entrypoint_docs) { File.read(File.join(repo_root, "docs/editor_entrypoint_affordances.md")) }

  it "exposes localized auto-fit result copy through the bundled editor root" do
    expect(editor_partial_source).to include("data-rails-table-preferences-resize-auto-fit-status-label-value")
    expect(editor_partial_source).to include("rails_table_preferences.editor.resize_auto_fit_status")
    expect(editor_partial_source).to include("列幅を自動調整しました。")
  end

  it "announces auto-fit completion through the existing status region" do
    expect(package_controller_source).to include("resizeAutoFitStatusLabel: { type: String, default: \"列幅を自動調整しました。\" }")
    expect(package_controller_source).to include("autoFitColumnFromHandle(event) {")
    expect(package_controller_source).to include("const result = super.autoFitColumnFromHandle(event)")
    expect(package_controller_source).to include("this.setStatus(this.resizeAutoFitStatusLabelValue, \"success\")")
  end

  it "keeps pointer double-click and keyboard auto-fit on the same feedback path" do
    expect(package_controller_source).to include("handle.addEventListener(\"keydown\", this.autoFitColumnFromResizeHandleKeyboard.bind(this))")
    expect(package_controller_source).to include("this.autoFitColumnFromHandle(event)")
    expect(package_controller_source).to include("return event.key === \"Enter\" || event.key === \" \" || event.key === \"Spacebar\"")
  end

  it "keeps manual drag resize as success-status clearing rather than saved-state feedback" do
    resize_column_source = package_controller_source[/resizeColumn\(event\) \{.*?\n  \}/m]

    expect(resize_column_source).to include("this.clearSuccessfulStatus()")
    expect(resize_column_source).not_to include("this.setStatus(")
    expect(resize_column_source).not_to include("resizeAutoFitStatusLabelValue")
  end

  it "keeps current column metadata when editor width values are rebuilt" do
    settings_from_editor_source = package_controller_source[/settingsFromEditor\(\) \{.*?\n  \}/m]

    expect(settings_from_editor_source).to include("const current = this.columnByKey(key) || {}")
    expect(settings_from_editor_source).to include("...current")
    expect(settings_from_editor_source).to include("width: this.clampColumnWidth(key")
    expect(settings_from_editor_source).to include("pinned: current.pinned === true")
  end

  it "documents the package-entrypoint-only feedback boundary" do
    expect(entrypoint_docs).to include("Resize auto-fit feedback")
    expect(entrypoint_docs).to include("rails_table_preferences.editor.resize_auto_fit_status")
    expect(entrypoint_docs).to include("Full keyboard resizing remains outside the package entrypoint first slice.")
  end
end
