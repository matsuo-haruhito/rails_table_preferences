# frozen_string_literal: true

require "spec_helper"

RSpec.describe "filter panel popup semantics" do
  let(:controller_source_path) do
    File.expand_path("../../app/javascript/controllers/rails_table_preferences_controller.js", __dir__)
  end

  let(:docs_path) do
    File.expand_path("../../docs/filter_panel_popup_semantics.md", __dir__)
  end

  let(:controller_source) { File.read(controller_source_path) }
  let(:docs) { File.read(docs_path) }

  it "keeps the bundled filter panel as a non-modal floating region" do
    expect(controller_source).to include('button.setAttribute("aria-expanded", "false")')
    expect(controller_source).to include('button.setAttribute("aria-controls", this.filterPanel.id)')
    expect(controller_source).to include('button.removeAttribute("aria-controls")')
    expect(controller_source).to include('panel.id = this.filterPanelId(column.key)')

    expect(controller_source).not_to include('aria-haspopup')
    expect(controller_source).not_to include('aria-modal')
    expect(controller_source).not_to match(/setAttribute\(["']role["'],\s*["']dialog["']\)/)
  end

  it "documents the current popup boundary and review checks" do
    expect(docs).to include("lightweight, non-modal floating region")
    expect(docs).to include("does not set `role=\"dialog\"`, `aria-modal`, or a focus trap")
    expect(docs).to include("does not expose `aria-haspopup`")
    expect(docs).to include("`aria-controls` points to the current panel id only while the panel is open")
    expect(docs).to include("Apply and Clear remain reachable in a short viewport")
  end
end
