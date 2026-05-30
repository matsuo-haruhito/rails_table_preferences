# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TableProfile do
  describe "inherited profile configuration" do
    let(:parent_profile) do
      Class.new(described_class) do
        model User
        only :name, :email
        exclude :created_at
        order :email, :name
        label :name, "Parent name"
        filter :status, type: "select", options: %w[active archived]
        column :metadata, details: {"source" => "parent", "nested" => {"scope" => "base"}}
      end
    end

    let(:child_profile) { Class.new(parent_profile) }

    it "copies the parent model, column lists, and overrides into the child profile" do
      expect(child_profile.model).to eq(User)
      expect(child_profile.only_columns).to eq(%w[name email])
      expect(child_profile.excluded_columns).to eq(%w[created_at])
      expect(child_profile.ordered_columns).to eq(%w[email name])
      expect(child_profile.column_overrides).to include(
        "name" => include("label" => "Parent name"),
        "status" => include("filter" => {"type" => "select", "options" => %w[active archived]}),
        "metadata" => include("details" => {"source" => "parent", "nested" => {"scope" => "base"}})
      )
    end

    it "keeps child overrides from mutating the parent profile" do
      child_profile.only :name
      child_profile.exclude :updated_at
      child_profile.order :name
      child_profile.label :name, "Child name"
      child_profile.column :metadata, details: {"source" => "child", "nested" => {"scope" => "child"}}

      expect(parent_profile.only_columns).to eq(%w[name email])
      expect(parent_profile.excluded_columns).to eq(%w[created_at])
      expect(parent_profile.ordered_columns).to eq(%w[email name])
      expect(parent_profile.column_overrides).to include(
        "name" => include("label" => "Parent name"),
        "metadata" => include("details" => {"source" => "parent", "nested" => {"scope" => "base"}})
      )

      expect(child_profile.only_columns).to eq(%w[name])
      expect(child_profile.excluded_columns).to eq(%w[created_at updated_at])
      expect(child_profile.ordered_columns).to eq(%w[name])
      expect(child_profile.column_overrides).to include(
        "name" => include("label" => "Child name"),
        "metadata" => include("details" => {"source" => "child", "nested" => {"scope" => "child"}})
      )
    end
  end

  describe ".apply" do
    it "appends profile columns that are not inferred" do
      formatter = ->(record, _view) { record.customer_name }
      profile = Class.new(described_class) do
        column :customer_name,
          label: "Customer",
          filter: { type: "text", param: "customer_name" },
          editor: { type: "readonly" },
          sortable: false,
          &formatter
      end

      columns = profile.apply([{ key: :order_no, label: "Order no" }])

      expect(columns.map { |column| column.fetch("key") }).to eq(%w[order_no customer_name])
      expect(columns.last).to include(
        "key" => "customer_name",
        "label" => "Customer",
        "filter" => { "type" => "text", "param" => "customer_name" },
        "editor" => { "type" => "readonly" },
        "sortable" => false,
        "formatter" => formatter
      )
    end

    it "orders virtual columns alongside inferred columns" do
      profile = Class.new(described_class) do
        order :customer_name, :order_no
        column :customer_name, label: "Customer"
      end

      columns = profile.apply([{ key: :order_no, label: "Order no" }, { key: :status, label: "Status" }])

      expect(columns.map { |column| column.fetch("key") }).to eq(%w[customer_name order_no status])
    end

    it "respects only and exclude for virtual columns" do
      profile = Class.new(described_class) do
        only :order_no, :customer_name, :internal_score
        exclude :internal_score
        column :customer_name, label: "Customer"
        column :internal_score, label: "Internal score"
        column :ignored_note, label: "Ignored note"
      end

      columns = profile.apply([{ key: :order_no, label: "Order no" }])

      expect(columns.map { |column| column.fetch("key") }).to eq(%w[order_no customer_name])
    end
  end
end
