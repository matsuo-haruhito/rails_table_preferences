# frozen_string_literal: true

RSpec.describe RailsTablePreferences::ColumnDefinition do
  describe "#to_h" do
    let(:column_with_comment) { Struct.new(:comment).new("顧客コード") }
    let(:model_with_comment) do
      column = column_with_comment
      Class.new do
        define_singleton_method(:columns_hash) { { "customer_code" => column } }
      end
    end

    it "builds a serializable column definition" do
      definition = described_class.new(
        key: :customer_code,
        label: "Customer Code",
        default_visible: "1",
        default_order: "10",
        default_width: "120",
        default_truncate: "20",
        overflow: :ellipsis,
        pinned: "0"
      )

      expect(definition.to_h).to eq(
        "key" => "customer_code",
        "label" => "Customer Code",
        "visible" => true,
        "order" => 10,
        "width" => 120,
        "truncate" => 20,
        "overflow" => "ellipsis",
        "pinned" => false,
        "ignored" => false
      )
    end

    it "includes normalized column width boundary metadata" do
      definition = described_class.new(
        key: :memo,
        label: "Memo",
        min_width: "80",
        max_width: "320"
      )

      expect(definition.to_h).to include(
        "min_width" => 80,
        "max_width" => 320
      )
    end

    it "omits non-positive column width boundary metadata" do
      definition = described_class.new(
        key: :memo,
        label: "Memo",
        min_width: 0,
        max_width: -1
      )

      expect(definition.to_h).not_to have_key("min_width")
      expect(definition.to_h).not_to have_key("max_width")
    end

    it "marks ignored columns" do
      definition = described_class.new(key: :internal_cost, ignored: true)

      expect(definition.to_h["ignored"]).to eq(true)
    end

    it "accepts ignore as an alias" do
      definition = described_class.new(key: :internal_cost, ignore: true)

      expect(definition.to_h["ignored"]).to eq(true)
    end

    it "normalizes overflow metadata" do
      expect(described_class.new(key: :memo, label: "Memo", overflow: :truncate).to_h["overflow"]).to eq("ellipsis")
      expect(described_class.new(key: :memo, label: "Memo", overflow: "wrap").to_h["overflow"]).to eq("wrap")
      expect(described_class.new(key: :memo, label: "Memo", overflow: :clip).to_h["overflow"]).to eq("clip")
      expect(described_class.new(key: :memo, label: "Memo", overflow: :nowrap).to_h["overflow"]).to eq("nowrap")
      expect(described_class.new(key: :memo, label: "Memo", overflow: :unknown).to_h).not_to have_key("overflow")
    end

    it "accepts default_overflow when overflow is not provided" do
      definition = described_class.new(key: :memo, label: "Memo", default_overflow: :ellipsis)

      expect(definition.to_h["overflow"]).to eq("ellipsis")
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
      definition = described_class.new(key: :customer_name, label: "得意先名", filter: true)

      expect(definition.to_h["filter"]).to eq("type" => "text")
    end

    it "accepts a symbol as a filter type shorthand" do
      definition = described_class.new(key: :status, label: "状態", filter: :select)

      expect(definition.to_h["filter"]).to eq("type" => "select")
    end

    it "omits filter metadata when disabled" do
      definition = described_class.new(key: :internal_note, label: "Internal note", filter: false)

      expect(definition.to_h).not_to have_key("filter")
    end

    it "includes sortable metadata when explicitly configured" do
      definition = described_class.new(key: :delivery_date, label: "Delivery date", sortable: "1")

      expect(definition.to_h["sortable"]).to eq(true)
    end

    it "omits sortable metadata when not configured" do
      definition = described_class.new(key: :delivery_date, label: "Delivery date")

      expect(definition.to_h).not_to have_key("sortable")
    end

    it "uses an explicit label first" do
      I18n.backend.store_translations(:en, attributes: { customer_code: "Localized customer code" })

      definition = described_class.new(key: :customer_code, label: "Customer Code")

      expect(definition.to_h["label"]).to eq("Customer Code")
    end

    it "uses a custom i18n key before database column comments" do
      I18n.backend.store_translations(:en, orders: { index: { columns: { customer_code: "Customer code for order list" } } })

      definition = described_class.new(
        key: :customer_code,
        i18n_key: "orders.index.columns.customer_code",
        model: model_with_comment
      )

      expect(definition.to_h["label"]).to eq("Customer code for order list")
    end

    it "uses database column comments by default" do
      definition = described_class.new(key: :customer_code, model: model_with_comment)

      expect(definition.to_h["label"]).to eq("顧客コード")
      expect(definition.to_h["ignored"]).to eq(false)
    end

    it "uses Active Record attribute translations when configured" do
      RailsTablePreferences.configuration.label_resolution = %i[activerecord_attribute_i18n]
      I18n.backend.store_translations(:en, activerecord: { attributes: { order: { customer_code: "Customer code from Order" } } })

      definition = described_class.new(key: :customer_code, model_name: :order)

      expect(definition.to_h["label"]).to eq("Customer code from Order")
    end

    it "uses Active Model attribute translations when configured" do
      RailsTablePreferences.configuration.label_resolution = %i[activemodel_attribute_i18n]
      I18n.backend.store_translations(:en, activemodel: { attributes: { order: { customer_code: "Customer code from Active Model" } } })

      definition = described_class.new(key: :customer_code, model_name: :order)

      expect(definition.to_h["label"]).to eq("Customer code from Active Model")
    end

    it "uses generic attribute translations when configured" do
      RailsTablePreferences.configuration.label_resolution = %i[attribute_i18n]
      I18n.backend.store_translations(:en, attributes: { generic_customer_code: "Generic customer code" })

      definition = described_class.new(key: :generic_customer_code)

      expect(definition.to_h["label"]).to eq("Generic customer code")
    end

    it "uses a humanized label when configured" do
      RailsTablePreferences.configuration.label_resolution = %i[humanize]

      definition = described_class.new(key: :delivery_due_date)

      expect(definition.to_h["label"]).to eq("Delivery due date")
      expect(definition.to_h["ignored"]).to eq(false)
    end

    it "marks unresolved labels as ignored by default" do
      definition = described_class.new(key: :delivery_due_date)

      expect(definition.to_h["label"]).to be_nil
      expect(definition.to_h["ignored"]).to eq(true)
    end

    it "can fallback to humanized labels when unresolved" do
      RailsTablePreferences.configuration.unresolved_label_behavior = :humanize

      definition = described_class.new(key: :delivery_due_date)

      expect(definition.to_h["label"]).to eq("Delivery due date")
      expect(definition.to_h["ignored"]).to eq(false)
    end

    it "can fallback to raw keys when unresolved" do
      RailsTablePreferences.configuration.unresolved_label_behavior = :key

      definition = described_class.new(key: :delivery_due_date)

      expect(definition.to_h["label"]).to eq("delivery_due_date")
    end
  end
end
