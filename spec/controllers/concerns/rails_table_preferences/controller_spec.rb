# frozen_string_literal: true

RSpec.describe RailsTablePreferences::Controller do
  let(:owner) { instance_double("User", id: 1) }
  let(:controller_class) do
    Class.new do
      include RailsTablePreferences::Controller

      def initialize(owner)
        @owner = owner
      end

      def current_user
        @owner
      end
    end
  end
  let(:controller) { controller_class.new(owner) }
  let(:scope) { instance_double("ActiveRecord::Relation") }
  let(:default_scope) { instance_double("ActiveRecord::Relation") }
  let(:ordered_default_scope) { instance_double("ActiveRecord::Relation") }

  before do
    RailsTablePreferences.configuration.current_user_method = :current_user
    allow(RailsTablePreferences::Preference).to receive(:for_user).with(owner).and_return(scope)
    allow(scope).to receive(:for_table).with(:orders).and_return(scope)
  end

  describe "#rails_table_preference" do
    it "finds an explicitly named preference" do
      preference = instance_double(RailsTablePreferences::Preference)
      allow(scope).to receive(:find_by).with(name: "inspection").and_return(preference)

      expect(controller.rails_table_preference(table_key: :orders, name: :inspection)).to eq(preference)
    end

    it "uses default_flag first when no name is given" do
      preference = instance_double(RailsTablePreferences::Preference)
      allow(scope).to receive(:defaults).and_return(default_scope)
      allow(default_scope).to receive(:order).with(:name).and_return(ordered_default_scope)
      allow(ordered_default_scope).to receive(:first).and_return(preference)

      expect(controller.rails_table_preference(table_key: :orders)).to eq(preference)
    end

    it "falls back to name default" do
      preference = instance_double(RailsTablePreferences::Preference)
      allow(scope).to receive(:defaults).and_return(default_scope)
      allow(default_scope).to receive(:order).with(:name).and_return(ordered_default_scope)
      allow(ordered_default_scope).to receive(:first).and_return(nil)
      allow(scope).to receive(:find_by).with(name: "default").and_return(preference)

      expect(controller.rails_table_preference(table_key: :orders)).to eq(preference)
    end
  end

  describe "#rails_table_preference_settings" do
    it "normalizes saved settings" do
      preference = instance_double(
        RailsTablePreferences::Preference,
        settings: {
          filters: { customer_name: { operator: :contains, value: "山田" } },
          sorts: [{ key: :delivery_date, direction: :DESC }]
        }
      )
      allow(scope).to receive(:find_by).with(name: "inspection").and_return(preference)

      expect(controller.rails_table_preference_settings(table_key: :orders, name: :inspection)).to eq(
        "columns" => [],
        "filters" => { "customer_name" => { "operator" => "contains", "value" => "山田" } },
        "sorts" => [{ "key" => "delivery_date", "direction" => "desc" }]
      )
    end
  end

  describe "#rails_table_preference_params" do
    it "returns controller params adapter output by default" do
      preference = instance_double(
        RailsTablePreferences::Preference,
        settings: {
          filters: { customer_name: { operator: :contains, value: "山田" } },
          sorts: [{ key: :delivery_date, direction: :desc }]
        }
      )
      columns = [
        { key: :customer_name, filter: { param: :search_word } },
        { key: :delivery_date, sort_param: :delivery_on }
      ]
      allow(scope).to receive(:find_by).with(name: "inspection").and_return(preference)

      expect(controller.rails_table_preference_params(table_key: :orders, name: :inspection, columns: columns)).to eq(
        "search_word" => "山田",
        "sort" => "-delivery_on"
      )
    end

    it "supports the Ransack adapter" do
      preference = instance_double(
        RailsTablePreferences::Preference,
        settings: {
          filters: { customer_name: { operator: :contains, value: "山田" } },
          sorts: [{ key: :delivery_date, direction: :desc }]
        }
      )
      allow(scope).to receive(:find_by).with(name: "inspection").and_return(preference)

      expect(controller.rails_table_preference_params(table_key: :orders, name: :inspection, columns: [], adapter: :ransack)).to eq(
        "customer_name_cont" => "山田",
        "s" => ["delivery_date desc"]
      )
    end
  end
end
