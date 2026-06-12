# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  before do
    RailsTablePreferences.configuration.unresolved_label_behavior = :humanize
  end

  describe "#table_preferences_params namespace" do
    it "keeps the existing flat controller params output when namespace is omitted" do
      params = helper.table_preferences_params(
        settings: {
          filters: {
            customer_name: { operator: :contains, value: "山田" },
            status: { operator: :in, values: %w[未出荷 出荷済] }
          },
          sorts: [{ key: :delivery_date, direction: :desc }]
        },
        columns: [
          { key: :customer_name, filter: { param: :search_word } },
          { key: :status, filter: { values_param: :statuses } },
          { key: :delivery_date, sort_param: :delivery_on }
        ]
      )

      expect(params).to eq(
        "search_word" => "山田",
        "statuses" => %w[未出荷 出荷済],
        "sort" => "-delivery_on"
      )
    end

    it "wraps controller params output in a nested hash when namespace is provided" do
      params = helper.table_preferences_params(
        settings: {
          filters: {
            customer_name: { operator: :contains, value: "山田" },
            status: { operator: :in, values: %w[未出荷 出荷済] },
            archived: { operator: :equals, value: false }
          },
          sorts: [{ key: :delivery_date, direction: :desc }]
        },
        columns: [
          { key: :customer_name, filter: { param: :search_word } },
          { key: :status, filter: { values_param: :statuses } },
          { key: :archived, filter: { param: :archived } },
          { key: :delivery_date, sort_param: :delivery_on }
        ],
        namespace: :search
      )

      expect(params).to eq(
        "search" => {
          "search_word" => "山田",
          "statuses" => %w[未出荷 出荷済],
          "archived" => false,
          "sort" => "-delivery_on"
        }
      )
    end

    it "wraps Ransack params output while preserving the sort array" do
      params = helper.table_preferences_params(
        settings: {
          filters: { customer_name: { operator: :contains, value: "山田" } },
          sorts: [{ key: :delivery_date, direction: :desc }]
        },
        columns: [:customer_name, :delivery_date],
        adapter: :ransack,
        namespace: :q
      )

      expect(params).to eq(
        "q" => {
          "customer_name_cont" => "山田",
          "s" => ["delivery_date desc"]
        }
      )
    end
  end
end
