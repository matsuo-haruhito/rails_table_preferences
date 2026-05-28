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
    expect(source).to include('><%= reset_label %></button>')
  end

  it "derives preset field ids from the per-editor prefix and keeps labels paired to them" do
    expect(source).to include('editor_instance_key = local_assigns[:editor_instance_key].presence || SecureRandom.hex(4)')
    expect(source).to include('editor_id_prefix = "rails-table-preferences-#{editor_id_key}"')
    expect(source).to include('preset_select_id = "#{editor_id_prefix}-preset-select"')
    expect(source).to include('preset_name_id = "#{editor_id_prefix}-preset-name"')
    expect(source).to include('<label for="<%= preset_select_id %>">')
    expect(source).to include('id="<%= preset_select_id %>"')
    expect(source).to include('<label for="<%= preset_name_id %>">')
    expect(source).to include('id="<%= preset_name_id %>"')
  end

  it "makes the bundled default preset checkbox explain that it takes effect on save" do
    expect(source).to include('default_preset_hint_id = "#{editor_id_prefix}-default-preset-hint"')
    expect(source).to include('default_preset_hint = t("rails_table_preferences.editor.default_preset_hint", default: "保存または別名保存すると、この設定を標準設定として登録します。")')
    expect(source).to include('data-rails-table-preferences-target="defaultPreset"')
    expect(source).to include('aria-describedby="<%= default_preset_hint_id %>"')
    expect(source).to include('<p id="<%= default_preset_hint_id %>" class="rails-table-preferences-editor__hint"><%= default_preset_hint %></p>')
  end
end
