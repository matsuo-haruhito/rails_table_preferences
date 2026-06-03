# frozen_string_literal: true

require_dependency RailsTablePreferences::Engine.root.join("app/helpers/rails_table_preferences/table_preferences_editor_html_options_helper").to_s

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  describe "#table_preferences_editor html_options" do
    it "passes id, aria, generic data, and merged classes to the editor root" do
      html = helper.table_preferences_editor(
        table_key: :orders,
        columns: [:customer_code],
        html_options: {
          id: "orders-table-settings",
          class: "drawer-panel",
          data: { turbo_frame: "orders_preferences" },
          aria: { label: "Orders table settings" }
        }
      )

      expect(html).to include('id="orders-table-settings"')
      expect(html).to include('class="rails-table-preferences-editor drawer-panel"')
      expect(html).to include('data-turbo-frame="orders_preferences"')
      expect(html).to include('aria-label="Orders table settings"')
    end

    it "keeps gem-owned controller data authoritative" do
      html = helper.table_preferences_editor(
        table_key: :orders,
        columns: [:customer_code],
        html_options: {
          data: {
            controller: "host-controller",
            rails_table_preferences_table_key_value: "wrong",
            "rails-table-preferences-url-value" => "/wrong",
            analytics_area: "drawer"
          }
        }
      )

      expect(html).to include('data-controller="rails-table-preferences"')
      expect(html).to include('data-rails-table-preferences-table-key-value="orders"')
      expect(html).to include('data-rails-table-preferences-url-value="/rails_table_preferences/preferences/orders/default"')
      expect(html).to include('data-analytics-area="drawer"')
      expect(html).not_to include("host-controller")
      expect(html).not_to include("/wrong")
    end

    it "keeps the default editor output wired when html_options are omitted" do
      html = helper.table_preferences_editor(table_key: :orders, columns: [:customer_code])

      expect(html).to include('class="rails-table-preferences-editor"')
      expect(html).to include('data-controller="rails-table-preferences"')
      expect(html).to include('data-action="rails-table-preferences#applyFromEditor"')
    end

    it "keeps compact helper text reachable from bundled editor controls" do
      html = helper.table_preferences_editor(table_key: :orders, columns: [:customer_code])
      hint_ids = html.scan(/id="([^"]+-hint)"/).flatten
      describedby_ids = html.scan(/aria-describedby="([^"]+)"/).flatten.flat_map(&:split)

      expected_hint_suffixes = %w[
        preset-select-hint
        preset-name-hint
        default-preset-hint
        action-hint
        reset-hint
      ]

      expected_hint_suffixes.each do |suffix|
        hint_id = hint_ids.find { |id| id.end_with?(suffix) }

        expect(hint_id).to be_present
        expect(describedby_ids).to include(hint_id)
      end
    end
  end
end
