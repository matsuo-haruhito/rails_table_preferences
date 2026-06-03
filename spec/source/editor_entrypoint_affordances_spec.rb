# frozen_string_literal: true

require "spec_helper"

RSpec.describe "editor package entrypoint affordances" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:controller_source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }
  let(:partial_source) { File.read(File.join(repo_root, "app/views/rails_table_preferences/_editor.html.erb")) }
  let(:stylesheet_source) { File.read(File.join(repo_root, "app/assets/stylesheets/rails_table_preferences.css")) }
  let(:docs_source) { File.read(File.join(repo_root, "docs/editor_entrypoint_affordances.md")) }

  it "keeps package entrypoint search and move affordances wired without changing the base controller" do
    expect(controller_source).to include("editorSearchLabel")
    expect(controller_source).to include("ensureEditorSearchControl")
    expect(controller_source).to include("syncEditorSearchResults")
    expect(controller_source).to include("buildEditorMoveControls")
    expect(controller_source).to include("moveEditorRow")
    expect(controller_source).to include("editorRowsForMovement")
  end

  it "keeps filtered editor rows in the DOM so editor settings are not dropped" do
    expect(controller_source).to include("this.editorRows.forEach((row) =>")
    expect(controller_source).to include("row.hidden = hidden")
    expect(controller_source).to include("if (!hidden) visibleCount += 1")
    expect(controller_source).to include("this.editorSearchEmptyMessage.hidden = !query || visibleCount > 0")
    expect(controller_source).not_to include("row.remove()")
    expect(controller_source).not_to include("removeChild(row)")
  end

  it "limits move actions to visible rows while preserving an all-row fallback" do
    expect(controller_source).to include("const visibleRows = this.editorRows.filter((row) => !row.hidden)")
    expect(controller_source).to include("return visibleRows.length > 0 ? visibleRows : this.editorRows")
    expect(controller_source).to include("const rows = this.editorRowsForMovement")
    expect(controller_source).to include("const target = rows[index + direction]")
  end

  it "updates order inputs after row moves before refreshing move-button state" do
    expect(controller_source).to match(/insertBefore\(row, target\).*insertBefore\(row, target\.nextSibling\).*refreshEditorOrderInputs\(\).*syncEditorMoveButtons\(\)/m)
  end

  it "disables generated move controls for busy, hidden, first, and last row states" do
    expect(controller_source).to include("button.disabled = this.busy || row.hidden || index < 0 ||")
    expect(controller_source).to include("direction === \"up\" ? index === 0 : index === rows.length - 1")
    expect(controller_source).to include("setEditorRowsBusyState(busy)")
    expect(controller_source).to include("super.setEditorRowsBusyState(busy)")
    expect(controller_source).to include("this.syncEditorMoveButtons()")
  end

  it "passes localized copy values from the bundled editor partial" do
    expect(partial_source).to include("data-rails-table-preferences-editor-search-label-value")
    expect(partial_source).to include("rails_table_preferences.editor.search_columns")
    expect(partial_source).to include("data-rails-table-preferences-move-up-label-value")
    expect(partial_source).to include("rails_table_preferences.editor.move_column_down")
  end

  it "keeps the generated controls styled across narrow editor rows" do
    expect(stylesheet_source).to include(".rails-table-preferences-editor__tools")
    expect(stylesheet_source).to include(".rails-table-preferences-editor__row-actions")
    expect(stylesheet_source).to include(".rails-table-preferences-editor__move-button")
    expect(stylesheet_source).to include("@media (max-width: 26rem)")
  end

  it "documents browser checks and the existing QA checklist routing" do
    expect(docs_source).to include("Use the bundled column search field")
    expect(docs_source).to include("Use the row up/down buttons")
    expect(docs_source).to include("docs/manual_qa.md")
    expect(docs_source).to include("docs/accessibility.md")
    expect(docs_source).to include("package entrypoint")
  end
end
