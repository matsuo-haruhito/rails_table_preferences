# frozen_string_literal: true

RSpec.describe RailsTablePreferences::Adapters::ActiveRecordColumns do
  before do
    RailsTablePreferences.configuration.label_resolution = [:key]
  end

  let(:customer_reflection) do
    Struct.new(:name, :foreign_key, :class_name).new(:customer, "customer_id", "Customer")
  end

  let(:model) do
    reflection = customer_reflection

    Object.new.tap do |model|
      model.define_singleton_method(:attribute_names) { %w[id order_no customer_id status created_at] }
      model.define_singleton_method(:defined_enums) { {} }
      model.define_singleton_method(:reflect_on_all_associations) do |type|
        type == :belongs_to ? [reflection] : []
      end
    end
  end

  def column_keys(columns)
    columns.map { |column| column.fetch("key") }
  end

  def filters_by_key(columns)
    columns.to_h { |column| [column.fetch("key"), column.fetch("filter")] }
  end

  it "infers belongs_to association columns by default" do
    columns = described_class.call(model: model)

    expect(column_keys(columns)).to eq(%w[order_no customer_id status customer])
  end

  it "treats only with a foreign key as raw attribute intent" do
    columns = described_class.call(model: model, only: %i[customer_id])

    expect(column_keys(columns)).to eq(%w[customer_id])
  end

  it "keeps other requested attributes without adding the association for a foreign key" do
    columns = described_class.call(model: model, only: %i[customer_id status])

    expect(column_keys(columns)).to eq(%w[customer_id status])
  end

  it "keeps the association convenience when only names the association" do
    columns = described_class.call(model: model, only: %i[customer])

    expect(column_keys(columns)).to eq(%w[customer])
  end

  it "keeps attribute-only inference when associations are disabled" do
    columns = described_class.call(model: model, only: %i[customer_id], include_associations: false)

    expect(column_keys(columns)).to eq(%w[customer_id])
  end

  it "keeps date, datetime, and time attributes on the date filter baseline" do
    attribute_type = Struct.new(:type)
    attribute_types = {
      "placed_on" => attribute_type.new(:date),
      "shipped_at" => attribute_type.new(:datetime),
      "dispatch_time" => attribute_type.new(:time),
      "active" => attribute_type.new(:boolean),
      "total" => attribute_type.new(:decimal),
      "status" => attribute_type.new(:string),
      "notes" => attribute_type.new(:text)
    }

    typed_model = Object.new.tap do |model|
      model.define_singleton_method(:attribute_names) do
        %w[placed_on shipped_at dispatch_time active total status notes]
      end
      model.define_singleton_method(:defined_enums) { { "status" => { "draft" => 0, "shipped" => 1 } } }
      model.define_singleton_method(:reflect_on_all_associations) { |_type = nil| [] }
      model.define_singleton_method(:type_for_attribute) { |name| attribute_types.fetch(name) }
    end

    columns = described_class.call(model: typed_model)

    expect(filters_by_key(columns)).to include(
      "placed_on" => { "type" => "date" },
      "shipped_at" => { "type" => "date" },
      "dispatch_time" => { "type" => "date" },
      "active" => { "type" => "boolean" },
      "total" => { "type" => "number" },
      "status" => { "type" => "select", "options" => %w[draft shipped] },
      "notes" => { "type" => "text" }
    )
  end
end
