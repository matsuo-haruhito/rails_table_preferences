# frozen_string_literal: true

RSpec.describe RailsTablePreferences::ColumnDefinition do
  describe "#to_h" do
    it "builds a serializable column definition" do
      definition = described_class.new(
        key: :customer_code,
        label: "Customer Code",
        default_visible: "1",
        default_order: "10",
        default_width: "120",
        default_truncate: "20",
        pinned: "0"
      )

      expect(definition.to_h).to eq(
        "key" => "customer_code",
        "label" => "Customer Code",
        "visible" => true,
        "order" => 10,
        "width" => 120,
        "truncate" => 20,
        "pinned" => false,
        "ignored" => false
      )
    end

    it "marks ignored columns" do
      definition = described_class.new(key: :internal_cost, ignored: true)

      expect(definition.to_h["ignored"]).to eq(true)
    end

    it "accepts ignore as an alias" do
      definition = described_class.new(key: :internal_cost, ignore: true)

      expect(definition.to_h["ignored"]).to eq(true)
    end

    it "includes normalized filter metadata" do
      definition = described_class.new(
        key: :customer_name,
        label: "得意先名",
        filter: {
          type: :text,
          operators: %i[contains equals blank]
        }
      )

      expect(definition.to_h).to include(
        "key" => "customer_name",
        "label" => "得意先名",
        "filter" => {
          "type" => "text",
          "operators" => %i[contains equals blank]
        }
      )
    end

    it "accepts true as a text filter shorthand" do
      definition = described_class.new(key: :customer_name, filter: true)

      expect(definition.to_h["filter"]).to eq("type" => "text")
    end

    it "accepts a symbol as a filter type shorthand" do
      definition = described_class.new(key: :status, filter: :select)

      expect(definition.to_h["filter"]).to eq("type" => "select")
    end

    it "omits filter metadata when disabled" do
      definition = described_class.new(key: :internal_note, filter: false)

      expect(definition.to_h).not_to have_key("filter")
    end

    it "includes sortable metadata when explicitly configured" do
      definition = described_class.new(key: :delivery_date, sortable: "1")

      expect(definition.to_h["sortable"]).to eq(true)
    end

    it "omits sortable metadata when not configured" do
      definition = described_class.new(key: :delivery_date)

      expect(definition.to_h).not_to have_key("sortable")
    end

    it "uses an explicit label first" do
      I18n.backend.store_translations(:en, attributes: { customer_code: "Localized customer code" })

      definition = described_class.new(key: :customer_code, label: "Customer Code")

      expect(definition.to_h["label"]).to eq("Customer Code")
    end

    it "uses a custom i18n key" do
      I18n.backend.store_translations(:en, orders: { index: { columns: { customer_code: "Customer code for order list" } } })

      definition = described_class.new(key: :customer_code, i18n_key: "orders.index.columns.customer_code")

      expect(definition.to_h["label"]).to eq("Customer code for order list")
    end

    it "uses Active Record attribute translations when a model name is given" do
      I18n.backend.store_translations(:en, activerecord: { attributes: { order: { customer_code: "Customer code from Order" } } })

      definition = described_class.new(key: :customer_code, model_name: :order)

      expect(definition.to_h["label"]).to eq("Customer code from Order")
    end

    it "uses generic attribute translations" do
      I18n.backend.store_translations(:en, attributes: { customer_code: "Generic customer code" })

      definition = described_class.new(key: :customer_code)

      expect(definition.to_h["label"]).to eq("Generic customer code")
    end

    it "uses a humanized label by default" do
      I18n.backend.store_translations(:en, attributes: { customer_code: nil })

      definition = described_class.new(key: :delivery_due_date)

      expect(definition.to_h["label"]).to eq("Delivery due date")
    end
  end
end
