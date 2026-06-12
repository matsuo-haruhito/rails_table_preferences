# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  describe "#table_preferences_table_tag scroll wrapper" do
    let(:columns) do
      [helper.table_preferences_column(:order_no, label: "Order no", fixed: true)]
    end

    it "does not render a wrapper by default" do
      html = helper.table_preferences_table_tag(
        table_key: :orders,
        columns: columns,
        class: "orders-table"
      ) { "content" }

      fragment = Nokogiri::HTML.fragment(html)

      expect(fragment.at_css(".rails-table-preferences-resource-table-scroll")).to be_nil
      expect(fragment.at_css("table.orders-table")).to be_present
    end

    it "wraps the table when scroll_wrapper is enabled" do
      html = helper.table_preferences_table_tag(
        table_key: :orders,
        columns: columns,
        scroll_wrapper: true,
        class: "orders-table"
      ) { "content" }

      fragment = Nokogiri::HTML.fragment(html)
      wrapper = fragment.at_css(".rails-table-preferences-resource-table-scroll")
      table = wrapper.at_css("table.orders-table")

      expect(wrapper.name).to eq("div")
      expect(table).to be_present
      expect(table["data-rails-table-preferences-table-key-value"]).to eq("orders")
    end

    it "keeps table options on the table and wrapper options on the wrapper" do
      html = helper.table_preferences_table_tag(
        table_key: :orders,
        columns: columns,
        scroll_wrapper: true,
        wrapper_options: {
          class: "orders-table-scroll",
          id: "orders-scroll",
          data: { controller: "scroll-frame" },
          aria: { label: "Orders table scroll area" }
        },
        id: "orders-table",
        class: "orders-table",
        data: { controller: "orders-table" },
        aria: { describedby: "orders-summary" }
      ) { "content" }

      fragment = Nokogiri::HTML.fragment(html)
      wrapper = fragment.at_css("#orders-scroll")
      table = fragment.at_css("#orders-table")

      expect(wrapper["class"]).to eq("rails-table-preferences-resource-table-scroll orders-table-scroll")
      expect(wrapper["data-controller"]).to eq("scroll-frame")
      expect(wrapper["aria-label"]).to eq("Orders table scroll area")
      expect(wrapper.at_css("table")).to eq(table)

      expect(table["class"]).to eq("orders-table")
      expect(table["aria-describedby"]).to eq("orders-summary")
      expect(table["data-controller"]).to eq("orders-table rails-table-preferences")
      expect(table["data-rails-table-preferences-table-key-value"]).to eq("orders")
    end

    it "accepts string-keyed wrapper class options" do
      html = helper.table_preferences_table_tag(
        table_key: :orders,
        columns: columns,
        scroll_wrapper: true,
        wrapper_options: { "class" => "string-key-scroll" }
      ) { "content" }

      wrapper = Nokogiri::HTML.fragment(html).at_css("div")

      expect(wrapper["class"]).to eq("rails-table-preferences-resource-table-scroll string-key-scroll")
    end
  end
end
