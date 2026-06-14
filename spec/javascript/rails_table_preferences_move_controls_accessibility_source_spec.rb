# frozen_string_literal: true

require "spec_helper"

RSpec.describe "package entrypoint editor move control accessibility" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:controller_source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }
  let(:reorder_note) { File.read(File.join(repo_root, "docs/editor_reorder_accessibility.md")) }

  def source_between(source, start_marker, end_marker)
    start_index = source.index(start_marker)
    end_index = source.index(end_marker, start_index || 0)
    return "" unless start_index && end_index

    source[start_index...end_index]
  end

  it "keeps generated move buttons named by localized labels with compact arrow text" do
    method_source = source_between(controller_source, "  buildEditorMoveButton(direction, label, text) {", "  moveEditorRow(event, direction) {")

    expect(method_source).to include('button.setAttribute("aria-label", label)')
    expect(method_source).to include("button.title = label")
    expect(method_source).to include("button.textContent = text")
    expect(method_source).to include('button.addEventListener("click", (event) => this.moveEditorRow(event, direction === "up" ? -1 : 1))')
    expect(method_source).not_to include("innerHTML")
  end

  it "documents the arrow glyph and accessible-name boundary" do
    expect(reorder_note).to include("The up/down move buttons keep their localized `aria-label` and `title` as the accessible name")
    expect(reorder_note).to include("The visible `↑` / `↓` glyphs are compact visual cues")
    expect(reorder_note).to include("forced-colors or high-contrast")
  end
end
