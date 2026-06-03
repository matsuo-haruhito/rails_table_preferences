# frozen_string_literal: true

require "spec_helper"

RSpec.describe "editor package entrypoint affordances" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:controller_source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }
  let(:partial_source) { File.read(File.join(repo_root, "app/views/rails_table_preferences/_editor.html.erb")) }
  let(:stylesheet_source) { File.read(File.join(repo_root, "app/assets/stylesheets/rails_table_preferences.css")) }
  let(:manual_qa_source) { File.read(File.join(repo_root, "docs/manual_qa.md")) }

  it "keeps package entrypoint search and move affordances wired without changing the base controller" do
    expect(controller_source).to include("editorSearchLabel")
    expect(controller_source).to include("ensureEditorSearchControl")
    expect(controller_source).to include("syncEditorSearchResults")
    expect(controller_source).to include("buildEditorMoveControls")
    expect(controller_source).to include("moveEditorRow")
    expect(controller_source).to include("editorRowsForMovement")
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

  it "documents the browser checks for searching and moving editor rows" do
    expect(manual_qa_source).to include("Use the bundled column search field")
    expect(manual_qa_source).to include("Use the row up/down buttons")
  end
end
