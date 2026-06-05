# frozen_string_literal: true

require "spec_helper"

RSpec.describe "resource table docs" do
  let(:resource_tables_doc) { File.read(File.expand_path("../../docs/resource_tables.md", __dir__)) }

  it "keeps the empty collection explicit model boundary visible" do
    empty_collection_section = markdown_section(resource_tables_doc, "### Model inference and empty collections")

    expect(empty_collection_section).to include(
      "Relation-like collections",
      "`records.klass`",
      "Plain arrays can still work when they contain at least one record",
      "When records do not expose `klass` and may be empty, pass the model explicitly or put the model on the profile",
      "resource_table_for [], model: Order",
      "class OrdersTableProfile < RailsTablePreferences::TableProfile",
      "model Order",
      "model: is required when records do not expose klass and are empty"
    )
  end

  def markdown_section(document, heading)
    document.split(heading, 2).last.split(/\n(?=##?\s)/, 2).first
  end
end
