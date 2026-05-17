# frozen_string_literal: true

RSpec.describe RailsTablePreferences::Adapters::ControllerParams do
  describe ".filter_params" do
    it "converts text filters to plain controller params" do
      expect(
        described_class.filter_params(
          filters: {
            customer_name: { operator: :contains, value: "山田" }
          }
        )
      ).to eq("customer_name" => "山田")
    end

    it "uses filter param metadata when present" do
      columns = [
        {
          key: :customer_name,
          filter: { type: :text, param: :search_customer_name }
        }
      ]

      expect(
        described_class.filter_params(
          filters: {
            customer_name: { operator: :contains, value: "山田" }
          },
          columns: columns
        )
      ).to eq("search_customer_name" => "山田")
    end

    it "adds an operator param when configured" do
      columns = [
        {
          key: :customer_name,
          filter: { type: :text, param: :customer_name, operator_param: :customer_name_operator }
        }
      ]

      expect(
        described_class.filter_params(
          filters: {
            customer_name: { operator: :starts_with, value: "山" }
          },
          columns: columns
        )
      ).to eq(
        "customer_name" => "山",
        "customer_name_operator" => "starts_with"
      )
    end

    it "converts between filters to from/to params" do
      expect(
        described_class.filter_params(
          filters: {
            delivery_date: { operator: :between, from: "2026-01-01", to: "2026-01-31" }
          }
        )
      ).to eq(
        "from_delivery_date" => "2026-01-01",
        "to_delivery_date" => "2026-01-31"
      )
    end

    it "uses custom from/to params when present" do
      columns = [
        {
          key: :delivery_date,
          filter: { type: :date, from_param: :from_date, to_param: :to_date }
        }
      ]

      expect(
        described_class.filter_params(
          filters: {
            delivery_date: { operator: :between, from: "2026-01-01", to: "2026-01-31" }
          },
          columns: columns
        )
      ).to eq(
        "from_date" => "2026-01-01",
        "to_date" => "2026-01-31"
      )
    end

    it "maps gteq and lteq to from/to params" do
      expect(
        described_class.filter_params(
          filters: {
            delivery_date: { operator: :gteq, value: "2026-01-01" },
            created_at: { operator: :lteq, value: "2026-01-31" }
          }
        )
      ).to eq(
        "from_delivery_date" => "2026-01-01",
        "to_created_at" => "2026-01-31"
      )
    end

    it "converts in filters to array params" do
      expect(
        described_class.filter_params(
          filters: {
            status: { operator: :in, values: %w[未出荷 出荷済] }
          }
        )
      ).to eq("status" => %w[未出荷 出荷済])
    end

    it "uses values_param for multi-value filters" do
      columns = [
        {
          key: :status,
          filter: { type: :select, values_param: :statuses }
        }
      ]

      expect(
        described_class.filter_params(
          filters: {
            status: { operator: :in, values: %w[未出荷 出荷済] }
          },
          columns: columns
        )
      ).to eq("statuses" => %w[未出荷 出荷済])
    end

    it "keeps operator-only filters as operator params" do
      expect(
        described_class.filter_params(
          filters: {
            memo: { operator: :blank }
          }
        )
      ).to eq("memo_operator" => "blank")
    end

    it "skips blank values" do
      expect(
        described_class.filter_params(
          filters: {
            customer_name: { operator: :contains, value: "" },
            status: { operator: :in, values: [] }
          }
        )
      ).to eq({})
    end
  end

  describe ".sort_params" do
    it "converts the first valid sort to a sort param" do
      expect(
        described_class.sort_params(
          sorts: [
            { key: :delivery_date, direction: :desc },
            { key: :customer_code, direction: :asc }
          ]
        )
      ).to eq("sort" => "-delivery_date")
    end

    it "uses ascending sort keys without a prefix" do
      expect(
        described_class.sort_params(
          sorts: [
            { key: :customer_code, direction: :asc }
          ]
        )
      ).to eq("sort" => "customer_code")
    end

    it "uses sort_param metadata when present" do
      columns = [
        { key: :delivery_date, sort_param: :new_arrival_date }
      ]

      expect(
        described_class.sort_params(
          sorts: [
            { key: :delivery_date, direction: :desc }
          ],
          columns: columns
        )
      ).to eq("sort" => "-new_arrival_date")
    end

    it "uses a custom top-level sort param name" do
      expect(
        described_class.sort_params(
          sorts: [
            { key: :delivery_date, direction: :desc }
          ],
          sort_param: :order
        )
      ).to eq("order" => "-delivery_date")
    end

    it "skips invalid sorts" do
      expect(
        described_class.sort_params(
          sorts: [
            { key: :delivery_date, direction: :sideways },
            { direction: :desc },
            { key: :customer_code, direction: :asc }
          ]
        )
      ).to eq("sort" => "customer_code")
    end
  end

  describe ".to_params" do
    it "combines filter and sort params" do
      columns = [
        { key: :customer_name, filter: { param: :search_word } },
        { key: :delivery_date, filter: { from_param: :from_date, to_param: :to_date }, sort_param: :delivery_on }
      ]

      expect(
        described_class.to_params(
          filters: {
            customer_name: { operator: :contains, value: "山田" },
            delivery_date: { operator: :between, from: "2026-01-01", to: "2026-01-31" }
          },
          sorts: [
            { key: :delivery_date, direction: :desc }
          ],
          columns: columns
        )
      ).to eq(
        "search_word" => "山田",
        "from_date" => "2026-01-01",
        "to_date" => "2026-01-31",
        "sort" => "-delivery_on"
      )
    end
  end
end
