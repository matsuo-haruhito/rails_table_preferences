# frozen_string_literal: true

require "spec_helper"
require "pathname"

RSpec.describe "editor i18n docs guard" do
  let(:repository_root) { Pathname.new(File.expand_path("../..", __dir__)) }
  let(:editor_partial) { read_file("app/views/rails_table_preferences/_editor.html.erb") }
  let(:editor_i18n_docs) { read_file("docs/editor_i18n.md") }

  it "documents every bundled editor locale key emitted by the ERB partial" do
    missing_keys = erb_locale_keys.reject { |key| documented_locale_key?(key) }

    expect(missing_keys).to eq([])
  end

  it "keeps the filter operator label family documented as a wildcard" do
    expect(documented_locale_keys).to include("rails_table_preferences.editor.filter_operator_labels.*")
    expect(documented_locale_key?("rails_table_preferences.editor.filter_operator_labels.contains")).to be(true)
  end

  def erb_locale_keys
    editor_partial
      .scan(/t\("(rails_table_preferences\.editor\.[^"]+)"/)
      .flatten
      .uniq
      .sort
  end

  def documented_locale_keys
    editor_i18n_docs
      .scan(/`(rails_table_preferences\.editor\.[^`]+)`/)
      .flatten
      .uniq
      .sort
  end

  def documented_locale_key?(key)
    documented_locale_keys.include?(key) || documented_wildcard_prefixes.any? do |prefix|
      key == prefix || key.start_with?("#{prefix}.")
    end
  end

  def documented_wildcard_prefixes
    documented_locale_keys
      .select { |key| key.end_with?(".*") }
      .map { |key| key.delete_suffix(".*") }
  end

  def read_file(relative_path)
    File.read(repository_root.join(relative_path))
  end
end
