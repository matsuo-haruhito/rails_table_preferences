# frozen_string_literal: true

RSpec.describe "locale files" do
  before do
    I18n.load_path += Dir[File.expand_path("../../config/locales/*.yml", __dir__)]
    I18n.backend.load_translations
  end

  it "provides Japanese editor labels" do
    I18n.with_locale(:ja) do
      expect(I18n.t("rails_table_preferences.editor.preset_select")).to eq("保存済み設定")
      expect(I18n.t("rails_table_preferences.editor.preset")).to eq("設定名")
      expect(I18n.t("rails_table_preferences.editor.default_preset")).to eq("標準設定にする")
      expect(I18n.t("rails_table_preferences.editor.apply")).to eq("適用")
      expect(I18n.t("rails_table_preferences.editor.save")).to eq("保存")
      expect(I18n.t("rails_table_preferences.editor.save_as_new")).to eq("別名で保存")
      expect(I18n.t("rails_table_preferences.editor.delete")).to eq("削除")
      expect(I18n.t("rails_table_preferences.editor.reset")).to eq("リセット")
      expect(I18n.t("rails_table_preferences.editor.order")).to eq("表示順")
      expect(I18n.t("rails_table_preferences.editor.width")).to eq("列幅")
      expect(I18n.t("rails_table_preferences.editor.truncate")).to eq("省略文字数")
      expect(I18n.t("rails_table_preferences.editor.drag_to_reorder")).to eq("ドラッグして並び替え")
      expect(I18n.t("rails_table_preferences.editor.resize_column")).to eq("列幅を変更")
    end
  end

  it "provides English editor labels" do
    I18n.with_locale(:en) do
      expect(I18n.t("rails_table_preferences.editor.preset_select")).to eq("Saved presets")
      expect(I18n.t("rails_table_preferences.editor.preset")).to eq("Preset")
      expect(I18n.t("rails_table_preferences.editor.default_preset")).to eq("Use as default")
      expect(I18n.t("rails_table_preferences.editor.apply")).to eq("Apply")
      expect(I18n.t("rails_table_preferences.editor.save")).to eq("Save")
      expect(I18n.t("rails_table_preferences.editor.save_as_new")).to eq("Save as new")
      expect(I18n.t("rails_table_preferences.editor.delete")).to eq("Delete")
      expect(I18n.t("rails_table_preferences.editor.reset")).to eq("Reset")
      expect(I18n.t("rails_table_preferences.editor.order")).to eq("Order")
      expect(I18n.t("rails_table_preferences.editor.width")).to eq("Width")
      expect(I18n.t("rails_table_preferences.editor.truncate")).to eq("Truncate")
      expect(I18n.t("rails_table_preferences.editor.drag_to_reorder")).to eq("Drag to reorder")
      expect(I18n.t("rails_table_preferences.editor.resize_column")).to eq("Resize column")
    end
  end
end
