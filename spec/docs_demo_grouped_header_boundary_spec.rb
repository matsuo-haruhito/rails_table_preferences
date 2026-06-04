# frozen_string_literal: true

require "spec_helper"

RSpec.describe "demo grouped header boundary docs" do
  subject(:demo_docs) { File.read(File.expand_path("../docs/demo.md", __dir__)) }

  it "keeps live leaf-column reordering separate from grouped header reload verification" do
    expect(demo_docs).to include("Apply and table-header drag update the leaf headers and body cells live")
    expect(demo_docs).to include("demo-only grouped header row is server-rendered")
    expect(demo_docs).to include("verified after save/reload")
    expect(demo_docs).to include("grouped header row remains a save/reload boundary")
  end
end
