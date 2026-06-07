# frozen_string_literal: true

require "spec_helper"
require "yaml"

RSpec.describe "editor locale inventory" do
  let(:root) { Pathname.new(__dir__).join("..") }
  let(:partial) { root.join("app/views/rails_table_preferences/_editor.html.erb").read }
  let(:editor_locale_keys) { partial.scan(/t\("rails_table_preferences\.editor\.([^"]+)"/).flatten.uniq.sort }

  def editor_locale(locale)
    YAML.load_file(root.join("config/locales/#{locale}.yml")).fetch(locale).fetch("rails_table_preferences").fetch("editor")
  end

  it "keeps bundled editor translation keys present in English and Japanese" do
    %w[en ja].each do |locale|
      missing_keys = editor_locale_keys - editor_locale(locale).keys

      expect(missing_keys).to be_empty, "#{locale}.yml is missing editor keys: #{missing_keys.join(", ")}"
    end
  end

  it "keeps English and Japanese editor locale inventories aligned" do
    en_keys = editor_locale("en").keys.sort
    ja_keys = editor_locale("ja").keys.sort

    expect(en_keys - ja_keys).to be_empty, "ja.yml is missing editor keys: #{(en_keys - ja_keys).join(", ")}"
    expect(ja_keys - en_keys).to be_empty, "en.yml is missing editor keys: #{(ja_keys - en_keys).join(", ")}"
  end
end
