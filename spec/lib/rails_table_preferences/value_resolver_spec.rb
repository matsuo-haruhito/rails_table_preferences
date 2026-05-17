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
end