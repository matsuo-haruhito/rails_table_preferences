# frozen_string_literal: true

require "spec_helper"
require "rails_table_preferences/package_verifier"

RSpec.describe "renderer registry docs guard" do
  let(:repository_root) { Pathname.new(File.expand_path("../..", __dir__)) }
  let(:docs_index) { read_doc("docs/index.md") }
  let(:resource_tables) { read_doc("docs/resource_tables.md") }

  it "keeps the renderer registry runtime file in the package verifier" do
    expect(RailsTablePreferences::PackageVerifier::REQUIRED_PATHS).to include(
      "lib/rails_table_preferences/renderer_registry.rb"
    )
  end

  it "keeps resource table docs routed to renderer registry guidance" do
    expect(docs_index).to include(
      "[Resource table adapters](resource_tables.md)",
      "register host-owned renderer mappings for TreeView or Rails Fields Kit controls"
    )

    expect(resource_tables).to include(
      "## Renderer registries",
      "Renderer registries convert filter/editor metadata into HTML without making Rails Table Preferences depend on a specific form helper library",
      "config.filter_renderers.register(\"rails_fields_kit\")",
      "config.editor_renderers.register(\"rails_fields_kit\")",
      "Rails Table Preferences owns column metadata, saved table state, adapter params, partial helper entrypoints, and renderer registry lookup",
      "The host app owns the final partial layout, route URLs, accepted params, selected-option preload behavior, query execution, authorization, and any validation or retry UI behind the rendered inputs"
    )
  end

  def read_doc(relative_path)
    File.read(repository_root.join(relative_path))
  end
end
