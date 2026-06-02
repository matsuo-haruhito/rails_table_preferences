# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  before do
    RailsTablePreferences.configuration.unresolved_label_behavior = :humanize
  end

  describe "#table_preferences_column" do
    it "passes export_key through as value-extraction metadata" do
      expect(helper.table_preferences_column(:customer_id, export_key: :customer_name, label: "得意先")).to include(
        "key" => "customer_id",
        "export_key" => "customer_name",
        "label" => "得意先"
      )
    end

    it "does not add export_key when it is not provided" do
      expect(helper.table_preferences_column(:customer_id, label: "得意先")).not_to have_key("export_key")
    end
  end
end
