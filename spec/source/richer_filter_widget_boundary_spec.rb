# frozen_string_literal: true

require "spec_helper"

RSpec.describe "richer filter widget integration boundary" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:filter_metadata_doc) { File.read(File.join(repo_root, "docs/filter_metadata.md")) }
  let(:resource_tables_doc) { File.read(File.join(repo_root, "docs/resource_tables.md")) }
  let(:non_goals_doc) { File.read(File.join(repo_root, "docs/non_goals.md")) }

  it "keeps the first slice on host-owned renderer registry examples" do
    expect(filter_metadata_doc).to include("Use the renderer registry path as the first slice")
    expect(filter_metadata_doc).to include("Rails Fields Kit end-to-end example")
    expect(resource_tables_doc).to include("## Rails Fields Kit end-to-end example")
    expect(resource_tables_doc).to include("first copyable richer-widget example")
    expect(resource_tables_doc).to include("register renderer mappings")
  end

  it "keeps richer widget behavior outside the bundled filter panel contract" do
    expect(filter_metadata_doc).to include("Rails Table Preferences owns the column key, filter metadata, saved filter state, and adapter params")
    expect(filter_metadata_doc).to include("The host app or external helper owns widget initialization")
    expect(filter_metadata_doc).to include("remote option loading, accepted query params, and authorization")
    expect(non_goals_doc).to include("Bundled richer filter widget dependencies")
    expect(non_goals_doc).to include("Rails Table Preferences should not bundle date pickers, autocomplete libraries, Select2-style widgets, or form-helper gem dependencies")
  end
end
