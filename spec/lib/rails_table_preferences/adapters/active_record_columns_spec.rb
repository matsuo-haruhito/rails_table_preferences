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
end
