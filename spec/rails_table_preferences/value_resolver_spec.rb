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

    it "does not rescue formatter exceptions into fallback values" do
      formatter = lambda { |_row| raise ArgumentError, "host formatter failed" }

      expect {
        described_class.call(record, { key: :customer_name, formatter: formatter }, view_context: view_context)
      }.to raise_error(ArgumentError, "host formatter failed")
    end

    it "keeps the attribute fallback when no formatter is configured" do
      expect(described_class.call(record, { key: :customer_name }, view_context: view_context))
        .to eq("Acme")
    end

    context "when no formatter is configured" do
      let(:fallback_record_class) do
        Class.new do
          def self.defined_enums
            { "status" => { "pending" => 0 } }
          end

          def self.type_for_attribute(name)
            Struct.new(:type).new(:boolean) if name == "active"
          end

          def initialize(attributes)
            @attributes = attributes.stringify_keys
          end

          def has_attribute?(name)
            @attributes.key?(name)
          end

          def read_attribute(name)
            @attributes.fetch(name)
          end
        end
      end

      it "renders nil as an empty string" do
        record = fallback_record_class.new(name: nil)

        expect(described_class.call(record, { key: :name }, view_context: view_context)).to eq("")
      end

      it "uses enum i18n readers before raw enum values" do
        record_class = Class.new(fallback_record_class) do
          def status_i18n
            "Pending review"
          end
        end
        record = record_class.new(status: "pending")

        expect(described_class.call(record, { key: :status }, view_context: view_context)).to eq("Pending review")
      end

      it "falls back to the raw enum value when no enum i18n reader exists" do
        record = fallback_record_class.new(status: "pending")

        expect(described_class.call(record, { key: :status }, view_context: view_context)).to eq("pending")
      end

      it "uses the boolean locale fallback labels for boolean attributes" do
        expect(described_class.call(fallback_record_class.new(active: true), { key: :active }, view_context: view_context))
          .to eq("Yes")
        expect(described_class.call(fallback_record_class.new(active: false), { key: :active }, view_context: view_context))
          .to eq("No")
      end

      it "uses view localization for time-like values" do
        value = Time.utc(2026, 6, 6, 12, 0, 0)
        localizing_view = double("view_context", l: "June 6, 2026 12:00")
        record = fallback_record_class.new(published_at: value)

        expect(described_class.call(record, { key: :published_at }, view_context: localizing_view))
          .to eq("June 6, 2026 12:00")
      end

      it "returns the original time-like value when localization cannot handle it" do
        value = Time.utc(2026, 6, 6, 12, 0, 0)
        failing_view = double("view_context")
        allow(failing_view).to receive(:l).with(value).and_raise(I18n::ArgumentError, "unsupported")
        record = fallback_record_class.new(published_at: value)

        expect(described_class.call(record, { key: :published_at }, view_context: failing_view)).to eq(value)
      end
    end
  end
end
