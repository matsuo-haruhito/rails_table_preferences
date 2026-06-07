# frozen_string_literal: true

RSpec.describe RailsTablePreferences::ValueResolver do
  it "reads Active Record attributes before reflective Ruby methods" do
    record_class = Class.new do
      def has_attribute?(name)
        name == "method"
      end

      def read_attribute(name)
        "attribute:#{name}"
      end
    end

    record = record_class.new

    expect(described_class.call(record, { key: :method, label: "Method" })).to eq("attribute:method")
  end

  it "does not call public methods that require arguments" do
    record_class = Class.new do
      def method(name)
        super
      end
    end

    record = record_class.new

    expect(described_class.call(record, { key: :method, label: "Method" })).to eq("")
  end

  it "still resolves zero-arity public readers for plain objects" do
    record_class = Class.new do
      def title
        "Readable title"
      end
    end

    record = record_class.new

    expect(described_class.call(record, { key: :title, label: "Title" })).to eq("Readable title")
  end

  it "passes the record to unary formatters" do
    record = Struct.new(:name).new("Order A")
    formatter = ->(formatted_record) { "formatted #{formatted_record.name}" }

    expect(described_class.call(record, { key: :name, formatter: formatter })).to eq("formatted Order A")
  end

  it "passes the record and view context to binary formatters" do
    record = Struct.new(:name).new("Order A")
    view_context = Object.new
    formatter = ->(formatted_record, context) { [formatted_record, context] }

    expect(described_class.call(record, { key: :name, formatter: formatter }, view_context: view_context)).to eq([record, view_context])
  end

  it "passes the record, stringified column, and view context to wider formatters" do
    record = Struct.new(:name).new("Order A")
    view_context = Object.new
    formatter = ->(formatted_record, column, context) { [formatted_record.name, column.fetch("key"), context] }

    expect(described_class.call(record, { key: :name, formatter: formatter }, view_context: view_context)).to eq([
      "Order A",
      "name",
      view_context
    ])
  end

  it "keeps nil formatter returns instead of falling back to the raw value" do
    record = Struct.new(:name).new("Fallback value")
    formatter = ->(_record) { nil }

    expect(described_class.call(record, { key: :name, formatter: formatter })).to be_nil
  end

  it "allows formatter exceptions to propagate" do
    error_class = Class.new(StandardError)
    record = Struct.new(:name).new("Order A")
    formatter = ->(_record) { raise error_class, "formatter failed" }

    expect { described_class.call(record, { key: :name, formatter: formatter }) }.to raise_error(error_class, "formatter failed")
  end
end
