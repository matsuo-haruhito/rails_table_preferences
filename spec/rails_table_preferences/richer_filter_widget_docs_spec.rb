# frozen_string_literal: true

RSpec.describe "richer filter widget documentation" do
  def repo_file(path)
    File.read(File.expand_path("../../#{path}", __dir__))
  end

  it "keeps richer widgets as a host-owned renderer registry path" do
    filter_metadata = repo_file("docs/filter_metadata.md")
    resource_tables = repo_file("docs/resource_tables.md")

    expect(filter_metadata).to include("renderer registry path as the first slice")
    expect(filter_metadata).to include("host-app-owned HTML")
    expect(filter_metadata).to include("resource_tables.md#rails-fields-kit-end-to-end-example")
    expect(filter_metadata).to include("not a promise that the bundled controller will gain autocomplete")
    expect(filter_metadata).to include("remote endpoints, query execution, authorization, validation copy, retry UI, selected-option preload policy")

    expect(resource_tables).to include("## Renderer registries")
    expect(resource_tables).to include("### Richer filter widget boundary")
    expect(resource_tables).to include("host-app HTML from a helper library")
    expect(resource_tables).to include("first copyable richer-widget example")
    expect(resource_tables).to include("Rails Fields Kit, Tom Select, or any other richer-widget dependency")
  end
end
