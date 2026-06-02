# frozen_string_literal: true

RSpec.describe "editor accessibility rendering", type: :helper do
  it "connects the bundled editor region to its visible title" do
    html = helper.table_preferences_editor(
      table_key: :orders,
      name: "inspection",
      title: "Order table settings",
      editor_instance_key: "review",
      columns: [:customer_code]
    )

    page = Capybara.string(html)
    editor = page.find(".rails-table-preferences-editor", visible: false)
    title_id = editor["aria-labelledby"]

    expect(editor["role"]).to eq("region")
    expect(title_id).to be_present
    expect(page.find("##{title_id}", visible: false).text).to eq("Order table settings")
  end

  it "keeps action descriptions backed by rendered helper text" do
    html = helper.table_preferences_editor(
      table_key: :orders,
      name: "inspection",
      editor_instance_key: "review",
      columns: [:customer_code]
    )

    page = Capybara.string(html)
    maintenance_group = page.find(".rails-table-preferences-editor__action-group--maintenance", visible: false)
    described_ids = maintenance_group["aria-describedby"].split

    expect(described_ids).not_to be_empty
    described_ids.each do |id|
      expect(page).to have_css("##{id}", visible: false)
    end

    delete_button = maintenance_group.find("button", text: "削除", visible: false)
    reset_button = maintenance_group.find("button", text: "テーブル初期設定に戻す", visible: false)

    [delete_button, reset_button].each do |button|
      button["aria-describedby"].split.each do |id|
        expect(page).to have_css("##{id}", visible: false)
      end
    end
  end
end
