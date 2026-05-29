# frozen_string_literal: true

RSpec.describe "generated demo export payload preview" do
  let(:template_path) do
    File.expand_path(
      "../../lib/generators/rails_table_preferences/install/templates/demo/index.html.erb",
      __dir__
    )
  end

  let(:template) { File.read(template_path) }

  it "compares default export payload with include-hidden export payload" do
    expect(template).to include("Export payload preview")
    expect(template).to include("include_hidden: true")
    expect(template).to include("Default column keys")
    expect(template).to include("Include-hidden column keys")
  end
end
