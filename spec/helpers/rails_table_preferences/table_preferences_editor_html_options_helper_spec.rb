# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  describe "#table_preferences_editor html_options" do
    it "injects host root attributes while keeping gem-owned data authoritative" do
      html = helper.table_preferences_editor(
        table_key: :orders,
        columns: [:customer_code],
        html_options: {
          id: "orders-editor",
          class: "orders-panel",
          data: {
            tracking_id: "editor",
            controller: "host-controller",
            rails_table_preferences_url_value: "/wrong"
          },
          aria: { label: "Orders table settings" }
        }
      )

      node = Nokogiri::HTML.fragment(html).at_css(".rails-table-preferences-editor")

      expect(node["id"]).to eq("orders-editor")
      expect(node["class"].split).to include("rails-table-preferences-editor", "orders-panel")
      expect(node["data-controller"]).to eq("rails-table-preferences")
      expect(node["data-tracking-id"]).to eq("editor")
      expect(node["data-rails-table-preferences-url-value"]).to eq("/rails_table_preferences/preferences/orders/default")
      expect(node["aria-label"]).to eq("Orders table settings")
    end

    it "merges host class into a custom partial root div without duplicating class attributes" do
      allow(helper).to receive(:render).and_return(
        %(<div class="custom-editor" role="region">Custom editor</div>)
      )

      html = helper.table_preferences_editor(
        table_key: :orders,
        columns: [],
        partial: "shared/custom_table_preferences_editor",
        html_options: {
          id: "custom-orders-editor",
          class: "orders-panel",
          data: { tracking_id: "editor" }
        }
      )

      node = Nokogiri::HTML.fragment(html).at_css("div")

      expect(html.scan(/\bclass=/).size).to eq(1)
      expect(node["id"]).to eq("custom-orders-editor")
      expect(node["class"].split).to include(
        "custom-editor",
        "rails-table-preferences-editor",
        "orders-panel"
      )
      expect(node["data-tracking-id"]).to eq("editor")
      expect(node["role"]).to eq("region")
    end

    it "leaves non-div custom partial roots unchanged when root attributes cannot be injected" do
      rendered = %(<section class="custom-editor">Custom editor</section>)
      allow(helper).to receive(:render).and_return(rendered)

      html = helper.table_preferences_editor(
        table_key: :orders,
        columns: [],
        partial: "shared/custom_table_preferences_editor",
        html_options: { id: "custom-orders-editor", class: "orders-panel" }
      )

      expect(html.to_s).to eq(rendered)
    end
  end
end
