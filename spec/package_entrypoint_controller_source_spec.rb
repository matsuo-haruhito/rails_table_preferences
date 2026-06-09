# frozen_string_literal: true

require "spec_helper"

RSpec.describe "package entrypoint controller source" do
  let(:controller_source_path) do
    File.expand_path("../app/javascript/rails_table_preferences/controller.js", __dir__)
  end

  let(:controller_declaration_path) do
    File.expand_path("../app/javascript/rails_table_preferences/controller.d.ts", __dir__)
  end

  let(:index_declaration_path) do
    File.expand_path("../app/javascript/rails_table_preferences/index.d.ts", __dir__)
  end

  let(:controller_source) { File.read(controller_source_path) }
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
    bulk_visibility_body = controller_source.match(/\n\s+setEditorColumnVisibility\(event, visible\) \{(?<body>.*?)\n\s+\}\n\n\s+buildEditorMoveControls/m)&.fetch(:body)

    expect(bulk_visibility_body).to include("this.editorRows.forEach((row) => {")
    expect(bulk_visibility_body).not_to include("this.editorRowsForMovement")
    expect(bulk_visibility_body).not_to include("!row.hidden")
  end

  it "keeps reset as a packaged success lifecycle action" do
    expect(controller_source).to include('this.dispatchPreferenceEvent("applied", { action: "reset" })')
    expect(controller_declaration).to include('export type RailsTablePreferencesSuccessAction = "apply" | "reset" | "save" | "create" | "load" | "delete"')
    expect(index_declaration).to include("RailsTablePreferencesSuccessAction")
  end
end
