# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TableState do
  describe ".call" do
    it "applies saved column state by key rather than duplicate column position" do
      state = described_class.call(
        columns: [
          { key: :customer, label: "Customer name", order: 1 },
          { key: :customer, label: "Customer code", order: 2 }
        ],
        settings: {
          columns: [
            { key: :customer, width: 120, order: 10 },
            { key: :customer, width: 180, order: 20 }
          ]
        }
      )

      expect(state["columns"].map { |column| column.slice("key", "label", "width", "order") }).to eq(
        [
          { "key" => "customer", "label" => "Customer name", "width" => 180, "order" => 20 },
          { "key" => "customer", "label" => "Customer code", "width" => 180, "order" => 20 }
        ]
      )
    end
  end
end
