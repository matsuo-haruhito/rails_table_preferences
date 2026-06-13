# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rails_table_preferences filter panel accessibility wiring" do
  let(:controller_source_path) do
    File.expand_path("../../app/javascript/rails_table_preferences/controller.js", __dir__)
  end
  let(:controller_source) { File.read(controller_source_path) }

  it "keeps the opened filter panel labelled by the generated title id" do
    expect(controller_source).to include(
      "this.filterPanel.setAttribute(\"role\", \"group\")",
      "this.filterPanel.setAttribute(\"aria-labelledby\", this.filterPanelTitleId(column.key))"
    )
  end

  it "keeps the title id derived from the shared panel id helper" do
    expect(controller_source).to include(
      "filterPanelTitleId(key) {",
      "return `${this.filterPanelId(key)}-title`"
    )
  end

  it "keeps rendered title id injection tied to the package filter panel title" do
    expect(controller_source).to include(
      "filterPanelHtml(column) {",
      "super.filterPanelHtml(column).replace(",
      "id=\"${this.filterPanelTitleId(column.key)}\" class=\"rails-table-preferences-filter-panel__title\""
    )
  end
end
