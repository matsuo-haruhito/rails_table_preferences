# frozen_string_literal: true

RSpec.describe "rails_table_preferences editor partial" do
  let(:source_path) do
    File.expand_path("../../app/views/rails_table_preferences/_editor.html.erb", __dir__)
  end

  let(:source) { File.read(source_path) }

  it "makes the bundled reset action explain that it returns to table defaults" do
    expect(source).to include('reset_label = t("rails_table_preferences.editor.reset", default: "テーブル初期設定に戻す")')
    expect(source).to include('reset_hint = t("rails_table_preferences.editor.reset_hint", default: "保存前の表示設定の変更を破棄し、読み込んだ保存済み設定ではなくテーブルの初期表示設定に戻します。")')
    expect(source).to include('reset_visible_hint = t("rails_table_preferences.editor.reset_visible_hint", default: "テーブル初期設定に戻すと、保存前の変更は破棄されます。読み込んだ保存済み設定へ戻す操作ではありません。")')
    expect(source).to include('data-action="rails-table-preferences#resetEditor"')
    expect(source).to include('title="<%= reset_hint %>"')
    expect(source).to include('aria-label="<%= reset_hint %>"')
    expect(source).to include('aria-describedby="<%= reset_hint_id %>"')
    expect(source).to include('><%= reset_label %></button>')
  end

  it "makes the bundled default preset checkbox explain that it takes effect on save" do
    expect(source).to include('default_preset_hint_id = "#{editor_id_prefix}-default-preset-hint"')
    expect(source).to include('default_preset_hint = t("rails_table_preferences.editor.default_preset_hint", default: "保存または別名保存すると、この設定を標準設定として登録します。")')
    expect(source).to include('data-rails-table-preferences-target="defaultPreset"')
    expect(source).to include('aria-describedby="<%= default_preset_hint_id %>"')
    expect(source).to include('<p id="<%= default_preset_hint_id %>" class="rails-table-preferences-editor__hint"><%= default_preset_hint %></p>')
  end
end