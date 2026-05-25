# frozen_string_literal: true

require "nokogiri"
require "spec_helper"

RSpec.describe "rails_table_preferences/_editor.html.erb", type: :view do
  let(:base_locals) do
    {
      title: "Orders",
      table_key: "orders",
      name: "default",
      preference_url: "/rails_table_preferences/preferences/orders/default",
      collection_url: "/rails_table_preferences/preferences/orders",
      settings_json: "{}",
      columns_json: "[]"
    }
  end

  def render_editor(editor_instance_key)
    view.render(
      partial: "rails_table_preferences/editor",
      locals: base_locals.merge(editor_instance_key: editor_instance_key)
    )
  end

  it "keeps preset ids unique and labels matched when two editors share the same page" do
    html = render_editor("left-pane") + render_editor("right-pane")
    fragment = Nokogiri::HTML.fragment(html)

    preset_select_ids = fragment.css("select[data-rails-table-preferences-target='presetSelect']").map { |node| node.fetch("id") }
    preset_name_ids = fragment.css("input[data-rails-table-preferences-target='presetName']").map { |node| node.fetch("id") }

    expect(preset_select_ids).to eq(
      [
        "rails-table-preferences-orders-default-left-pane-preset-select",
        "rails-table-preferences-orders-default-right-pane-preset-select"
      ]
    )
    expect(preset_name_ids).to eq(
      [
        "rails-table-preferences-orders-default-left-pane-preset-name",
        "rails-table-preferences-orders-default-right-pane-preset-name"
      ]
    )
    expect(preset_select_ids.uniq).to eq(preset_select_ids)
    expect(preset_name_ids.uniq).to eq(preset_name_ids)

    editor_nodes = fragment.css(".rails-table-preferences-editor")
    expect(editor_nodes.size).to eq(2)

    preset_select_label = I18n.t("rails_table_preferences.editor.preset_select", default: "保存済み設定")
    preset_name_label = I18n.t("rails_table_preferences.editor.preset", default: "設定名")

    expect(editor_nodes[0].at_css("label[for='#{preset_select_ids[0]}']")&.text&.strip).to eq(preset_select_label)
    expect(editor_nodes[0].at_css("label[for='#{preset_name_ids[0]}']")&.text&.strip).to eq(preset_name_label)
    expect(editor_nodes[1].at_css("label[for='#{preset_select_ids[1]}']")&.text&.strip).to eq(preset_select_label)
    expect(editor_nodes[1].at_css("label[for='#{preset_name_ids[1]}']")&.text&.strip).to eq(preset_name_label)
  end
end
