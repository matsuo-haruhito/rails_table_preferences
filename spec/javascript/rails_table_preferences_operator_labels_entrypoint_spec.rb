# frozen_string_literal: true

RSpec.describe "rails_table_preferences/controller operator labels" do
  let(:entrypoint_path) do
    File.expand_path("../../app/javascript/rails_table_preferences/controller.js", __dir__)
  end

  let(:entrypoint_source) { File.read(entrypoint_path) }

  it "adds a root value for filter operator label overrides" do
    expect(entrypoint_source).to include("filterOperatorLabels: { type: Object, default: {} }")
    expect(entrypoint_source).to include("filterOperatorLabelsValue?.[key]")
  end

  it "keeps the bundled controller fallback for default and unknown operator labels" do
    expect(entrypoint_source).to include("return super.filterOperatorText(key)")
    expect(entrypoint_source).to include("String(override).trim() !== \"\"")
  end
end
