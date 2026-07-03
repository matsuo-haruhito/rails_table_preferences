# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Generated demo preview copy fallback cues" do
  let(:root) { File.expand_path("../../..", __dir__) }
  let(:view_template) do
    File.read(File.join(root, "lib/generators/rails_table_preferences/install/templates/demo/index.html.erb"))
  end

  it "keeps hidden fields and export payload previews available as manual evidence when copy is unavailable" do
    expect(view_template).to include(
      "data-rails-table-preferences-demo-copy-target=\"rails-table-preferences-demo-hidden-fields-preview\"",
      "data-rails-table-preferences-demo-copy-target=\"rails-table-preferences-demo-export-payload-preview\"",
      "data-rails-table-preferences-demo-copy-status",
      "role=\"status\"",
      "aria-live=\"polite\""
    )

    expect(view_template).to include(
      "このブラウザではコピーできません。プレビュー本文を選択してください。",
      "コピーに失敗しました。プレビュー本文を選択してください。",
      "コピーできる内容はまだありません。"
    )
  end
end
