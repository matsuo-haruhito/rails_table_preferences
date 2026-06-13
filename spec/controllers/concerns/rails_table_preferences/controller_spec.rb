# frozen_string_literal: true

RSpec.describe RailsTablePreferences::Controller do
  let(:owner) { instance_double("User", id: 1) }
  let(:scope_context) { { roles: ["admin"], organization: "tokyo" } }
  let(:controller_class) do
    Class.new do
      include RailsTablePreferences::Controller

      def initialize(owner)
        @owner = owner
      end

      private

      def current_user
        @owner
      end

      def table_preference_scope_context
        { roles: ["admin"], organization: "tokyo" }
      end
    end
  end
  let(:controller) { controller_class.new(owner) }

  before do
    RailsTablePreferences.configuration.current_user_method = :current_user
    RailsTablePreferences.configuration.scope_context_method = :table_preference_scope_context
  end

  describe "#rails_table_preference" do
    it "finds an explicitly named available preference" do
      preference = instance_double(RailsTablePreferences::Preference)
      allow(RailsTablePreferences::Preference).to receive(:available_named_preference).and_return(preference)

      expect(controller.rails_table_preference(table_key: :orders, name: :inspection)).to eq(preference)
      expect(RailsTablePreferences::Preference).to have_received(:available_named_preference).with(
        user: owner,
        table_key: :orders,
        name: :inspection,
        scope_context: scope_context
      )
    end

    it "uses scoped default preference resolution when no name is given" do
      preference = instance_double(RailsTablePreferences::Preference)
      allow(RailsTablePreferences::Preference).to receive(:default_for).and_return(preference)

      expect(controller.rails_table_preference(table_key: :orders)).to eq(preference)
      expect(RailsTablePreferences::Preference).to have_received(:default_for).with(
        user: owner,
        table_key: :orders,
        scope_context: scope_context
      )
    end

    it "accepts an explicit scope context override" do
      preference = instance_double(RailsTablePreferences::Preference)
      allow(RailsTablePreferences::Preference).to receive(:default_for).and_return(preference)

      expect(controller.rails_table_preference(table_key: :orders, scope_context: { roles: ["manager"] })).to eq(preference)
      expect(RailsTablePreferences::Preference).to have_received(:default_for).with(
        user: owner,
        table_key: :orders,
        scope_context: { roles: ["manager"] }
      )
    end
  end

  describe "#rails_table_preference_settings" do
    it "normalizes saved settings" do
      preference = instance_double(
        RailsTablePreferences::Preference,
        settings: {
          filters: { customer_name: { operator: :contains, value: "Yamada" } },
          sorts: [{ key: :delivery_date, direction: :DESC }]
        }
      )
      allow(RailsTablePreferences::Preference).to receive(:available_named_preference).and_return(preference)

      expect(controller.rails_table_preference_settings(table_key: :orders, name: :inspection)).to eq(
        "columns" => [],
        "filters" => { "customer_name" => { "operator" => "contains", "value" => "Yamada" } },
        "sorts" => [{ "key" => "delivery_date", "direction" => "desc" }]
      )
    end
  end

  describe "#rails_table_preference_params" do
    it "returns controller params adapter output by default" do
      preference = instance_double(
        RailsTablePreferences::Preference,
        settings: {
          filters: { customer_name: { operator: :contains, value: "Yamada" } },
          sorts: [{ key: :delivery_date, direction: :desc }]
        }
      )
      columns = [
        { key: :customer_name, filter: { param: :search_word } },
        { key: :delivery_date, sort_param: :delivery_on }
      ]
      allow(RailsTablePreferences::Preference).to receive(:available_named_preference).and_return(preference)

      expect(controller.rails_table_preference_params(table_key: :orders, name: :inspection, columns: columns)).to eq(
        "search_word" => "Yamada",
        "sort" => "-delivery_on"
      )
    end

    it "uses fallback settings when no preference is resolved" do
      columns = [
        { key: :customer_name, filter: { param: :search_word } },
        { key: :status, filter: { values_param: :statuses } },
        { key: :delivery_date, sort_param: :delivery_on }
      ]
      fallback = {
        filters: {
          customer_name: { operator: :contains, value: "Yamada" },
          status: { operator: :in, value: ["pending", false] }
        },
        sorts: [{ key: :delivery_date, direction: :desc }]
      }
      allow(RailsTablePreferences::Preference).to receive(:default_for).and_return(nil)

      expect(controller.rails_table_preference_params(table_key: :orders, columns: columns, fallback: fallback)).to eq(
        "search_word" => "Yamada",
        "statuses" => ["pending", false],
        "sort" => "-delivery_on"
      )
    end

    it "passes fallback settings through the Ransack adapter" do
      fallback = {
        filters: { customer_name: { operator: :contains, value: "Yamada" } },
        sorts: [{ key: :delivery_date, direction: :desc }]
      }
      allow(RailsTablePreferences::Preference).to receive(:default_for).and_return(nil)

      expect(controller.rails_table_preference_params(table_key: :orders, columns: [], adapter: :ransack, fallback: fallback)).to eq(
        "customer_name_cont" => "Yamada",
        "s" => ["delivery_date desc"]
      )
    end

    it "prefers saved settings over fallback settings" do
      preference = instance_double(
        RailsTablePreferences::Preference,
        settings: {
          filters: { customer_name: { operator: :contains, value: "Saved" } },
          sorts: [{ key: :delivery_date, direction: :asc }]
        }
      )
      columns = [
        { key: :customer_name, filter: { param: :search_word } },
        { key: :delivery_date, sort_param: :delivery_on }
      ]
      fallback = {
        filters: { customer_name: { operator: :contains, value: "Fallback" } },
        sorts: [{ key: :delivery_date, direction: :desc }]
      }
      allow(RailsTablePreferences::Preference).to receive(:default_for).and_return(preference)

      expect(controller.rails_table_preference_params(table_key: :orders, columns: columns, fallback: fallback)).to eq(
        "search_word" => "Saved",
        "sort" => "delivery_on"
      )
    end

    it "supports the Ransack adapter" do
      preference = instance_double(
        RailsTablePreferences::Preference,
        settings: {
          filters: { customer_name: { operator: :contains, value: "Yamada" } },
          sorts: [{ key: :delivery_date, direction: :desc }]
        }
      )
      allow(RailsTablePreferences::Preference).to receive(:available_named_preference).and_return(preference)

      expect(controller.rails_table_preference_params(table_key: :orders, name: :inspection, columns: [], adapter: :ransack)).to eq(
        "customer_name_cont" => "Yamada",
        "s" => ["delivery_date desc"]
      )
    end
  end

  describe "#rails_table_preference_merged_params" do
    it "merges fallback-derived params over the base params" do
      columns = [
        { key: :customer_name, filter: { param: :search_word } },
        { key: :delivery_date, sort_param: :delivery_on }
      ]
      fallback = {
        filters: { customer_name: { operator: :contains, value: "Fallback" } },
        sorts: [{ key: :delivery_date, direction: :desc }]
      }
      allow(RailsTablePreferences::Preference).to receive(:default_for).and_return(nil)

      expect(
        controller.rails_table_preference_merged_params(
          { page: "3", search_word: "Request" },
          table_key: :orders,
          columns: columns,
          fallback: fallback,
          sort_param: :order
        )
      ).to eq(
        "page" => "3",
        "search_word" => "Fallback",
        "order" => "-delivery_on"
      )
    end
  end

  describe "#rails_table_preference_export_payload" do
    it "returns an export payload from the resolved settings" do
      preference = instance_double(
        RailsTablePreferences::Preference,
        settings: {
          columns: [
            { key: :customer_name, visible: true, order: 10 },
            { key: :order_no, visible: true, order: 20 }
          ]
        }
      )
      columns = [
        { key: :order_no, label: "Order No." },
        { key: :customer_name, label: "Customer" }
      ]
      allow(RailsTablePreferences::Preference).to receive(:available_named_preference).and_return(preference)

      payload = controller.rails_table_preference_export_payload(table_key: :orders, name: :inspection, columns: columns)

      expect(payload["column_keys"]).to eq(%w[customer_name order_no])
      expect(payload["headers"]).to eq(["Customer", "Order No."])
    end
  end
end
