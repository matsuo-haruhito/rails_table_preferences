# frozen_string_literal: true

require "spec_helper"

RSpec.describe "package entrypoint controller source" do
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

  let(:controller_source) { File.read(controller_source_path) }
  let(:base_controller_source) { File.read(base_controller_source_path) }
  let(:controller_declaration) { File.read(controller_declaration_path) }
  let(:index_declaration) { File.read(index_declaration_path) }

  it "keeps filterValueHtml as a single package entrypoint override" do
    expect(controller_source.scan(/\n\s+filterValueHtml\(filter, condition, selectedOperator\) \{/).size).to eq(1)
    expect(controller_source).to include("return super.filterValueHtml(filter, condition, selectedOperator)")
  end

  it "keeps select filters on the option-search source of truth" do
    expect(controller_source).to include("const value = this.selectFilterOptionValue(option)")
    expect(controller_source).to include("const label = this.selectFilterOptionLabel(option, value)")
    expect(controller_source).to include("${this.selectFilterOptionSearchHtml(filter.options)}<select data-field=\"values\" multiple>")
    expect(controller_source).to include("selectFilterOptionSearchThreshold: { type: Number, default: 8 }")
    expect(controller_source).to include("const threshold = Number(this.selectFilterOptionSearchThresholdValue)")
    expect(controller_source).to include("if (!Number.isFinite(threshold)) return 8")
    expect(controller_source).to include("return Math.floor(threshold)")
  end

  it "keeps visibility bulk actions scoped to all editor rows" do
    bulk_visibility_body = controller_source.match(/\n\s+setEditorColumnVisibility\(event, visible\) \{(?<body>.*?)\n\s+\}\n\n\s+buildEditorMoveControls/m)&.[](:body)

    expect(bulk_visibility_body).not_to be_nil
    expect(bulk_visibility_body).to include("this.editorRows.forEach((row) => {")
    expect(bulk_visibility_body).not_to include("this.editorRowsForMovement")
    expect(bulk_visibility_body).not_to include("!row.hidden")
  end

  it "keeps reset as a packaged success lifecycle action" do
    expect(controller_source).to include('this.dispatchPreferenceEvent("applied", { action: "reset" })')
    expect(controller_declaration).to include('export type RailsTablePreferencesSuccessAction = "apply" | "reset" | "save" | "create" | "load" | "delete"')
    expect(index_declaration).to include("RailsTablePreferencesSuccessAction")
  end

  it "keeps editor search as a package entrypoint-only visibility filter" do
    expect(controller_source).to include("this.ensureEditorSearchControl()")
    expect(controller_source).to include("this.syncEditorSearchResults()")
    expect(controller_source).to include("row.hidden = hidden")
    expect(controller_source).to include("if (this.editorSearchEmptyMessage) this.editorSearchEmptyMessage.hidden = !query || visibleCount > 0")
    expect(base_controller_source).not_to include("ensureEditorSearchControl")
    expect(base_controller_source).not_to include("syncEditorSearchResults")
  end

  it "keeps hidden editor rows in apply/save settings while moves use visible rows" do
    expect(base_controller_source).to include("const columns = this.editorRows.map((row, index) => {")
    expect(controller_source).to include("const visibleRows = this.editorRows.filter((row) => !row.hidden)")
    expect(controller_source).to include("return visibleRows.length > 0 ? visibleRows : this.editorRows")
    expect(controller_source).to include("button.disabled = this.busy || row.hidden || index < 0 || (direction === \"up\" ? index === 0 : index === rows.length - 1)")
  end

  it "keeps the status-state hook scoped to packaged status feedback" do
    expect(controller_source).to include('this.statusState = "idle"')
    expect(controller_source).to include('target.setAttribute("data-rails-table-preferences-status-state", state || "idle")')
    expect(controller_source).to include('if (busyLabel) this.setStatus(busyLabel, "busy")')
    expect(controller_source).to include('if (successLabel) this.setStatus(successLabel, "success")')
    expect(controller_source).to include('if (this.statusState === "success") this.setStatus("")')
    expect(controller_source).to include('this.statusState = "error"')
    expect(controller_source).to include('this.syncStatusStateHook("error")')
    expect(base_controller_source).not_to include("data-rails-table-preferences-status-state")
  end
end
