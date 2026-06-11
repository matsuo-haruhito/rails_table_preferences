# frozen_string_literal: true

require "spec_helper"

RSpec.describe "generated demo export payload preview" do
  let(:controller_source) do
    File.read(
      File.expand_path(
        "../../lib/generators/rails_table_preferences/install/templates/demo/orders_controller.rb",
        __dir__
      )
    )
  end

  let(:template_source) do
    File.read(
      File.expand_path(
        "../../lib/generators/rails_table_preferences/install/templates/demo/index.html.erb",
        __dir__
      )
    )
  end

  let(:demo_docs) do
    File.read(File.expand_path("../../docs/demo.md", __dir__))
  end

  it "uses a representative export_key column in the generated demo" do
    expect(controller_source).to include(":customer_name")
    expect(controller_source).to include("label: \"得意先名\"")
    expect(controller_source).to include("export_key: :customer_display_name")
  end

  it "shows column keys and export keys for both default and include-hidden payloads" do
    expect(template_source).to include("<dt>Default column keys</dt>")
    expect(template_source).to include("<dt>Default export keys</dt>")
    expect(template_source).to include("@export_payload_preview.fetch(\"export_keys\", [])")
    expect(template_source).to include("<dt>Include-hidden column keys</dt>")
    expect(template_source).to include("<dt>Include-hidden export keys</dt>")
    expect(template_source).to include("export_payload_with_hidden_preview.fetch(\"export_keys\", [])")
  end

  it "keeps the demo guide aligned with the export key preview" do
    expect(demo_docs).to include("`headers`, `column_keys`, and `export_keys`")
    expect(demo_docs).to include("export_key metadata")
  end
end
