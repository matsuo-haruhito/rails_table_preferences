# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  describe "#table_preferences_column_groups" do
    it "groups normalized columns by group metadata" do
      columns = [
        helper.table_preferences_column(:customer_code, label: "得意先コード", group: { key: :customer, label: "得意先情報" }),
        helper.table_preferences_column(:customer_name, label: "得意先名", group: { key: :customer, label: "得意先情報" }),
        helper.table_preferences_column(:delivery_date, label: "納品日", group: { key: :delivery, label: "配送情報" })
      ]
      normalized_columns = helper.table_preferences_columns(columns)

      groups = helper.table_preferences_column_groups(columns)

      expect(groups).to eq(
        [
          {
            "key" => "customer",
            "label" => "得意先情報",
            "columns" => normalized_columns.first(2),
            "colspan" => 2
          },
          {
            "key" => "delivery",
            "label" => "配送情報",
            "columns" => [normalized_columns.last],
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

    it "excludes ignored columns from groups and colspan" do
      columns = [
        helper.table_preferences_column(:order_no, label: "Order No", group: { key: :order, label: "Order information" }),
        helper.table_preferences_column(:order_total, label: "Order Total", group: { "key" => "order", "label" => "Order information" }),
        helper.table_preferences_column(:customer_name, label: "Customer", group: "Customer"),
        helper.table_preferences_column(:internal_cost, label: "Internal Cost", group: { key: :order, label: "Order information" }, ignored: true),
        helper.table_preferences_column(:secret_note, label: "Secret Note", group: "Internal"),
        helper.table_preferences_column(:notes, label: "Notes")
      ]

      groups = helper.table_preferences_column_groups(columns, ignored_columns: [:secret_note])

      expect(groups.map { |group| group.slice("key", "label", "colspan") }).to eq([
        { "key" => "order", "label" => "Order information", "colspan" => 2 },
        { "key" => "Customer", "label" => "Customer", "colspan" => 1 },
        { "key" => "", "label" => "", "colspan" => 1 }
      ])
      expect(groups.first.fetch("columns").map { |column| column.fetch("key") }).to eq(%w[order_no order_total])
      expect(groups.last.fetch("columns").map { |column| column.fetch("key") }).to eq(%w[notes])
      expect(groups.flat_map { |group| group.fetch("columns").map { |column| column.fetch("key") } }).not_to include(
        "internal_cost",
        "secret_note"
      )
    end
  end
end
