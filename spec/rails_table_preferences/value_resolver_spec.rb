# frozen_string_literal: true

RSpec.describe RailsTablePreferences::ValueResolver do
  describe ".call" do
    let(:record_class) { Struct.new(:customer_name, keyword_init: true) }
    let(:record) { record_class.new(customer_name: "Acme") }
    let(:view_context) { double("view_context", customer_link: "linked Acme") }

    it "calls one-argument formatters with the record" do
      formatter = lambda { |row| "customer: #{row.customer_name}" }

      expect(described_class.call(record, { key: :customer_name, formatter: formatter }, view_context: view_context))
        .to eq("customer: Acme")
    end

    it "calls two-argument formatters with the record and view context" do
      formatter = lambda { |row, view| "#{view.customer_link} / #{row.customer_name}" }

      expect(described_class.call(record, { key: :customer_name, formatter: formatter }, view_context: view_context))
        .to eq("linked Acme / Acme")
    end

    it "calls three-or-more-argument formatters with the record, column, and view context" do
      formatter = lambda { |row, column, view| "#{row.customer_name}:#{column.fetch("key")}:#{view.customer_link}" }

      expect(described_class.call(record, { key: :customer_name, formatter: formatter }, view_context: view_context))
        .to eq("Acme:customer_name:linked Acme")
    end

    it "returns nil from a formatter as the current presentation result" do
      formatter = lambda { |_row| nil }

      expect(described_class.call(record, { key: :customer_name, formatter: formatter }, view_context: view_context))
        .to be_nil
    end

    it "keeps the attribute fallback when no formatter is configured" do
      expect(described_class.call(record, { key: :customer_name }, view_context: view_context))
        .to eq("Acme")
    end
  end
end
