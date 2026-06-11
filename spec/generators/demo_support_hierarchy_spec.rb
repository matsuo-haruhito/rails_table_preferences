# frozen_string_literal: true

RSpec.describe "generated demo support section hierarchy" do
  let(:template_path) do
    File.expand_path(
      "../../lib/generators/rails_table_preferences/install/templates/demo/index.html.erb",
      __dir__
    )
  end

  let(:template) { File.read(template_path) }

  it "keeps secondary verification blocks behind collapsible summaries" do
    expect(template).to include('<details class="rails-table-preferences-demo-summary rails-table-preferences-demo-support-details">')
    expect(template).to include('<summary>Search form hidden fields preview</summary>')
    expect(template).to include('<summary>Export payload preview</summary>')
    expect(template).to include('<summary>Demo state reset</summary>')
    expect(template).to include('<summary>Async failure check</summary>')
  end
end