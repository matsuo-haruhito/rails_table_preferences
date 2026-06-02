# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rails_table_preferences JavaScript controller source" do
  subject(:controller_source) do
    File.read(File.expand_path("../../app/javascript/rails_table_preferences/controller.js", __dir__))
  end

  it "renders escaped placeholder attributes for bundled value filters" do
    expect(controller_source).to include("filterPlaceholderAttribute(filter.placeholder)")
    expect(controller_source).to include("filterPlaceholderAttribute(filter.from_placeholder)")
    expect(controller_source).to include("filterPlaceholderAttribute(filter.to_placeholder)")
    expect(controller_source).to include('return ` placeholder="${this.escapeHtml(text)}"`')
  end

  it "keeps select filters on their existing options-only rendering path" do
    expect(controller_source).to include('filter.type === "select" && Array.isArray(filter.options)')
    expect(controller_source).to include('data-field="values" multiple')
  end
end
