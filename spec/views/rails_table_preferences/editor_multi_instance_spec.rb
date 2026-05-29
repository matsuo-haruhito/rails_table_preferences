# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rails_table_preferences/_editor", type: :view do
  def render_editor(instance_key)
    view.render(
      partial: "rails_table_preferences/editor",
      locals: {
        table_key: "orders",
        name: "default",
        editor_instance_key: instance_key,
        title: "Table settings",
        preference_url: "/table_preferences/orders/default",
        collection_url: "/table_preferences/orders",
        settings_json: "{}",
        columns_json: "[]"
      }
    )
  end

  it "keeps preset controls and helper ids isolated for multiple editors on one page" do
    html = Capybara.string([
      render_editor("primary"),
      render_editor("secondary")
    ].join)

    ids = html.all("[id]").map { |node| node[:id] }
    duplicate_ids = ids.tally.select { |_id, count| count > 1 }

    expect(duplicate_ids).to be_empty

    %w[primary secondary].each do |instance_key|
      prefix = "rails-table-preferences-orders-default-#{instance_key}"
      preset_select_id = "#{prefix}-preset-select"
      preset_name_id = "#{prefix}-preset-name"
      preset_select_hint_id = "#{prefix}-preset-select-hint"
      preset_name_hint_id = "#{prefix}-preset-name-hint"

      expect(html).to have_css(%(label[for="#{preset_select_id}"]))
      expect(html).to have_css(%(select##{preset_select_id}[aria-describedby="#{preset_select_hint_id}"]))
      expect(html).to have_css(%(p##{preset_select_hint_id}))

      expect(html).to have_css(%(label[for="#{preset_name_id}"]))
      expect(html).to have_css(%(input##{preset_name_id}[aria-describedby="#{preset_name_hint_id}"]))
      expect(html).to have_css(%(p##{preset_name_hint_id}))
    end
  end
end
