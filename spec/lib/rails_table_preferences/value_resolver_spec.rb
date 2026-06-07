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

  it "passes only the record to unary formatters" do
    record = Struct.new(:name).new("Order A")
    formatter = ->(value) { "formatted:#{value.name}" }

    expect(described_class.call(record, { key: :name, formatter: formatter })).to eq("formatted:Order A")
  end

  it "passes the record and view context to binary formatters" do
    record = Struct.new(:name).new("Order A")
    view_context = instance_double("ViewContext")
    formatter = ->(value, context) { [value, context] }

    result = described_class.call(
      record,
      { key: :name, formatter: formatter },
      view_context: view_context
    )

    expect(result).to eq([record, view_context])
  end

  it "passes the record, column, and view context to wider formatters" do
    record = Struct.new(:name).new("Order A")
    view_context = instance_double("ViewContext")
    formatter = ->(value, column, context) { [value.name, column.fetch(:key), context] }

    result = described_class.call(
      record,
      { key: :name, formatter: formatter },
      view_context: view_context
    )

    expect(result).to eq(["Order A", :name, view_context])
  end

  it "keeps nil formatter results instead of falling back to the default value" do
    record = Struct.new(:name).new("Order A")
    formatter = ->(_value) {}

    expect(described_class.call(record, { key: :name, formatter: formatter })).to be_nil
  end

  it "lets formatter exceptions propagate" do
    record = Struct.new(:name).new("Order A")
    error_class = Class.new(StandardError)
    formatter = ->(_value) { raise error_class, "formatter failed" }

    expect do
      described_class.call(record, { key: :name, formatter: formatter })
    end.to raise_error(error_class, "formatter failed")
  end
end
