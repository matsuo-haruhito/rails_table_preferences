# frozen_string_literal: true

RSpec.describe RailsTablePreferences::Preference do
  describe ".find_for" do
    it "finds a preference for the given user table and name" do
      user = User.create!(name: "User 1")
      preference = described_class.create!(
        user: user,
        table_key: "orders",
        name: "default",
        settings: { "columns" => [] }
      )

      expect(described_class.find_for(user: user, table_key: :orders)).to eq(preference)
    end
  end

  describe ".find_or_initialize_for" do
    it "initializes a default preference for the user and table" do
      user = User.create!(name: "User 1")

      preference = described_class.find_or_initialize_for(user: user, table_key: :orders)

      expect(preference).to be_new_record
      expect(preference.user).to eq(user)
      expect(preference.table_key).to eq("orders")
      expect(preference.name).to eq("default")
    end
  end

  describe "validations" do
    it "requires unique names per user and table" do
      user = User.create!(name: "User 1")
      described_class.create!(user: user, table_key: "orders", name: "default", settings: { "columns" => [] })

      duplicate = described_class.new(user: user, table_key: "orders", name: "default", settings: { "columns" => [] })

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end
  end

  describe "defaults" do
    it "sets a default name and settings" do
      user = User.create!(name: "User 1")
      preference = described_class.create!(user: user, table_key: "orders")

      expect(preference.name).to eq("default")
      expect(preference.settings).to eq("columns" => [], "filters" => {}, "sorts" => [])
    end
  end
end
