# frozen_string_literal: true

RSpec.describe "RailsTablePreferences JavaScript select filter options" do
  subject(:controller_source) do
    File.read(File.expand_path("../app/javascript/rails_table_preferences/controller.js", __dir__))
  end

  it "renders object option values separately from visible labels" do
    expect(controller_source).to include("selectFilterOptionValue(option)")
    expect(controller_source).to include("selectFilterOptionLabel(option")
    expect(controller_source).to include("option.value ?? option.label ?? \"\"")
    expect(controller_source).to include("option.label ?? option.value ?? fallbackValue")
  end

  it "keeps selected state based on option values" do
    expect(controller_source).to include("values.has(String(value))")
    expect(controller_source).to include("<option value=\"${this.escapeHtml(value)}\"")
    expect(controller_source).to include(">${this.escapeHtml(label)}</option>")
  end
end
