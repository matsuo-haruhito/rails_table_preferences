# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  def render_editor(name:, editor_instance_key:)
    helper.render(
      partial: RailsTablePreferences.configuration.editor_partial,
      locals: {
        table_key: "orders",
        name: name,
        title: "Order table settings",
        settings: {},
        columns: [],
        settings_json: "{}",
        columns_json: "[]",
        preference_url: "/rails_table_preferences/preferences/orders/#{ERB::Util.url_encode(name)}",
        collection_url: "/rails_table_preferences/preferences/orders",
        editor_instance_key: editor_instance_key
      }
    )
  end

  it "keeps preset labels and inputs unique across multiple editors on one page" do
    rendered = render_editor(name: "default", editor_instance_key: "left pane") +
      render_editor(name: "archived view", editor_instance_key: "right pane")

    first_select_id = "rails-table-preferences-orders-default-left-pane-preset-select"
    first_name_id = "rails-table-preferences-orders-default-left-pane-preset-name"
    second_select_id = "rails-table-preferences-orders-archived-view-right-pane-preset-select"
    second_name_id = "rails-table-preferences-orders-archived-view-right-pane-preset-name"

    [first_select_id, first_name_id, second_select_id, second_name_id].each do |dom_id|
      expect(rendered.scan(%(id="#{dom_id}")).size).to eq(1)
    end

    expect(rendered.scan(%(for="#{first_select_id}")).size).to eq(1)
    expect(rendered.scan(%(for="#{first_name_id}")).size).to eq(1)
    expect(rendered.scan(%(for="#{second_select_id}")).size).to eq(1)
    expect(rendered.scan(%(for="#{second_name_id}")).size).to eq(1)

    editor_field_ids = rendered.scan(/id="([^"]+)"/).flatten.select do |dom_id|
      dom_id.end_with?("-preset-select") || dom_id.end_with?("-preset-name")
    end

    expect(editor_field_ids).to eq(editor_field_ids.uniq)
  end
end
