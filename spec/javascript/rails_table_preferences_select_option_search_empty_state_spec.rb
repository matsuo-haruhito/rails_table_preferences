# frozen_string_literal: true

RSpec.describe "RailsTablePreferences package select option search empty state" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }

  it "renders a package no-results message next to the select option search input" do
    expect(source).to include("data-rails-table-preferences-option-search-empty")
    expect(source).to include("一致する候補はありません。選択済みの候補は表示したままです。")
    expect(source).to include("aria-live=\"polite\"")
  end

  it "shows the no-results message only when no option matches the query" do
    expect(source).to include("let matchingOptions = 0")
    expect(source).to include("if (matchesQuery) matchingOptions += 1")
    expect(source).to include("if (emptyMessage) emptyMessage.hidden = !query || matchingOptions > 0")
    expect(source).not_to include("matchingUnselectedOptions")
  end

  it "keeps selected options visible even when they do not match the query" do
    expect(source).to include("option.hidden = Boolean(query) && !option.selected && !matchesQuery")
  end

  it "keeps scalar and label-value option handling on the existing package path" do
    expect(source).to include("const value = this.selectFilterOptionValue(option)")
    expect(source).to include("const label = this.selectFilterOptionLabel(option, value)")
    expect(source).to include("return String(option.value ?? option.label ?? \"\")")
    expect(source).to include("return String(option.label ?? option.value ?? fallbackValue)")
  end
end
