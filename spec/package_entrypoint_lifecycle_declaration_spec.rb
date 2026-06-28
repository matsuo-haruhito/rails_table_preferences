# frozen_string_literal: true

require "spec_helper"

RSpec.describe "package entrypoint lifecycle declaration" do
  let(:root) { File.expand_path("..", __dir__) }
  let(:controller_source) { read_source("app/javascript/rails_table_preferences/controller.js") }
  let(:controller_declaration) { read_source("app/javascript/rails_table_preferences/controller.d.ts") }
  let(:index_declaration) { read_source("app/javascript/rails_table_preferences/index.d.ts") }
  let(:javascript_docs) { read_source("docs/javascript_controller.md") }

  it "keeps clear-filters-and-sorts aligned across dispatch, docs, and TypeScript declarations" do
    expect(controller_source).to include('this.dispatchPreferenceEvent("applied", { action: "clear-filters-and-sorts" })')
    expect(controller_declaration).to include('"clear-filters-and-sorts"')
    expect(controller_declaration).to include("export type RailsTablePreferencesSuccessAction")
    expect(index_declaration).to include("RailsTablePreferencesSuccessAction")
    expect(javascript_docs).to include('event.detail.action === "clear-filters-and-sorts"')
  end

  def read_source(relative_path)
    File.read(File.join(root, relative_path))
  end
end
