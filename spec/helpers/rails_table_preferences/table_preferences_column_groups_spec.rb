# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  describe "#table_preferences_column_groups" do
    it "groups columns by group metadata" do
      columns = [
        helper.table_preferences_column(:customer_code, label: "得意先コード", group: { key: :customer, label: "得意先情報" }),
        helper.table_preferences_column(:customer_name, label: "得意先名", group: { key: :customer, label: "得意先情報" }),
        helper.table_preferences_column(:delivery_date, label: "納品日", group: { key: :delivery, label: "配送情報" })
      ]

      groups = helper.table_preferences_column_groups(columns)

      expect(groups).to eq(
        [
          {
            "key" => "customer",
            "label" => "得意先情報",
            "columns" => columns.first(2),
            "colspan" => 2
          },
          {
            "key" => "delivery",
            "label" => "配送情報",
            "columns" => [columns.last],
            "colspan" => 1
          }
        ]
      )
    end

    it "keeps ungrouped columns in an empty group" do
      columns = [
        helper.table_preferences_column(:order_no, label: "受注番号"),
        helper.table_preferences_column(:customer_name, label: "得意先名", group: :customer)
      ]

      groups = helper.table_preferences_column_groups(columns)

      expect(groups.first).to include("key" => "", "label" => "", "colspan" => 1)
      expect(groups.last).to include("key" => "customer", "label" => "customer", "colspan" => 1)
    end
  end
end
