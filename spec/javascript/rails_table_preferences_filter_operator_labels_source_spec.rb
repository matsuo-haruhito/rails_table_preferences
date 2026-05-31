# frozen_string_literal: true

RSpec.describe "rails_table_preferences filter operator label overrides" do
  let(:package_controller_path) do
    File.expand_path("../../app/javascript/rails_table_preferences/controller.js", __dir__)
  end

  let(:docs_path) do
    File.expand_path("../../docs/javascript_controller.md", __dir__)
  end

  let(:package_controller_source) { File.read(package_controller_path) }
  let(:docs_source) { File.read(docs_path) }

  it "exposes a package-root Stimulus value for operator label overrides" do
    expect(package_controller_source).to include("filterOperatorLabels: { type: Object, default: {} }")
    expect(package_controller_source).to include("filterOperatorText(operator)")
    expect(package_controller_source).to include("const key = String(operator)")
    expect(package_controller_source).to include("const override = this.filterOperatorLabelsValue?.[key]")
  end

  it "falls back to the bundled operator labels for missing or blank overrides" do
    expect(package_controller_source).to include('if (override !== undefined && override !== null && String(override).trim() !== "") return String(override)')
    expect(package_controller_source).to include("return super.filterOperatorText(key)")
  end

  it "documents the root data value used by host apps" do
    expect(docs_source).to include("data-rails-table-preferences-filter-operator-labels-value")
    expect(docs_source).to include("Keys are operator names")
    expect(docs_source).to include("Operators omitted from the object keep the bundled Japanese defaults")
  end
end
