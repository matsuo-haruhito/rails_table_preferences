# frozen_string_literal: true

RSpec.describe "rails_table_preferences editor partial" do
  let(:source_path) do
    File.expand_path("../../app/views/rails_table_preferences/_editor.html.erb", __dir__)
  end

  let(:source) { File.read(source_path) }

  it "makes the bundled reset action explain that current edits are discarded" do
    expect(source).to include('reset_label = t("rails_table_preferences.editor.reset", default: "初期状態に戻す")')
    expect(source).to include('reset_hint = t("rails_table_preferences.editor.reset_hint", default: "保存前の表示設定の変更を破棄して、初期状態に戻します。")')
    expect(source).to include('data-action="rails-table-preferences#resetEditor"')
    expect(source).to include('title="<%= reset_hint %>"')
    expect(source).to include('aria-label="<%= reset_hint %>"')
    expect(source).to include('aria-describedby="<%= reset_hint_id %>"')
    expect(source).to include('class="rails-table-preferences-editor__actions-hint"')
  end
end
