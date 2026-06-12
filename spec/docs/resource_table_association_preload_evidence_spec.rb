# frozen_string_literal: true

require "spec_helper"

RSpec.describe "resource table association preload evidence docs" do
  let(:repository_root) { Pathname.new(__dir__).join("../..").expand_path }
  let(:resource_table_docs) { File.read(repository_root.join("docs/resource_tables.md")) }
  let(:production_checklist) { File.read(repository_root.join("docs/production_integration_checklist.md")) }
  let(:manual_qa_checklist) { File.read(repository_root.join("docs/manual_qa.md")) }

  it "keeps association formatter ownership in the resource table guide" do
    expect(resource_table_docs).to include(
      "Rails Table Preferences does not infer joins, eager loading, authorization policy, or business-specific association labels."
    )
    expect(resource_table_docs).to include(
      "The host app still owns the relation, any preloading needed by the formatter, and any search/sort behavior behind a virtual filter or sort param."
    )
    expect(resource_table_docs).to include(
      "Formatter code remains presentation-only; the host app still owns eager loading, authorization-aware redaction, and business-specific fallbacks."
    )
  end

  it "keeps production evidence focused on host-app preload checks" do
    expect(production_checklist).to include(
      "When a resource table profile formatter reads associations, such as `order.customer`, preload those associations in the host-app relation before rendering"
    )
    expect(production_checklist).to include(
      "render representative rows while watching the host app's query log or existing N+1 guard and confirm the relation preloads those associations explicitly"
    )
    expect(production_checklist).to include(
      "downstream host app still needs its own adoption evidence for each real table surface"
    )
  end

  it "keeps manual QA as the browser-facing check for formatter preload evidence" do
    expect(manual_qa_checklist).to include(
      "If a resource table profile formatter reads associations, confirm the host app relation preloads those associations and that a query log or existing N+1 guard stays clean for representative rows."
    )
    expect(manual_qa_checklist).to include("`track:quality`: start with the invariant or regression area the PR protects")
    expect(manual_qa_checklist).to include("Manual QA focuses on browser behavior, host app integration, accessibility, and visual/UX issues")
  end
end
