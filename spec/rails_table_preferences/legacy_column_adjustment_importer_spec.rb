# frozen_string_literal: true

RSpec.describe RailsTablePreferences::LegacyColumnAdjustmentImporter do
  before do
    stub_const("ColumnAdjustment", legacy_model)
  end

  let(:legacy_model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "column_adjustments"
    end
  end

  before do
    ActiveRecord::Schema.define do
      suppress_messages do
        create_table :column_adjustments, force: true do |t|
          t.string :setting_name
          t.string :table_name
          t.json :value
          t.integer :create_user_id
          t.timestamps
        end
      end
    end
  end

  describe "#call" do
    it "imports legacy ColumnAdjustment records" do
      user = User.create!(name: "User 1")
      ColumnAdjustment.create!(
        setting_name: "default",
        table_name: "orders",
        create_user_id: user.id,
        value: [
          {
            "column_name" => "customer_code",
            "display_flag" => false,
            "display_order" => 20,
            "width" => 160
          }
        ]
      )

      result = described_class.new.call

      preference = RailsTablePreferences::Preference.find_for(user: user, table_key: "orders", name: "default")
      expect(result.created).to eq(1)
      expect(result.updated).to eq(0)
      expect(result.skipped).to eq(0)
      expect(preference.settings).to eq(
        "columns" => [
          {
            "key" => "customer_code",
            "visible" => false,
            "order" => 20,
            "width" => 160,
            "pinned" => false
          }
        ],
        "filters" => {},
        "sorts" => []
      )
    end

    it "skips records without a resolvable user" do
      ColumnAdjustment.create!(setting_name: "default", table_name: "orders", value: [])

      result = described_class.new.call

      expect(result.created).to eq(0)
      expect(result.skipped).to eq(1)
    end

    it "supports dry runs" do
      user = User.create!(name: "User 1")
      ColumnAdjustment.create!(setting_name: "default", table_name: "orders", create_user_id: user.id, value: [])

      result = described_class.new(dry_run: true).call

      expect(result.created).to eq(1)
      expect(RailsTablePreferences::Preference.count).to eq(0)
    end
  end
end
