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
end
