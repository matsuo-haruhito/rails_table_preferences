# frozen_string_literal: true

RSpec.describe RailsTablePreferences::Configuration do
  describe "owner model configuration" do
    it "defaults to User and user_id" do
      configuration = described_class.new

      expect(configuration.user_class_name).to eq("User")
      expect(configuration.user_foreign_key).to eq("user_id")
      expect(configuration.owner_class_name).to eq("User")
      expect(configuration.owner_foreign_key).to eq("user_id")
    end

    it "accepts a plural symbol" do
      configuration = described_class.new

      configuration.owner_model = :customers

      expect(configuration.user_class_name).to eq("Customer")
      expect(configuration.user_foreign_key).to eq("customer_id")
    end

    it "accepts a plural string" do
      configuration = described_class.new

      configuration.owner_model = "clients"

      expect(configuration.user_class_name).to eq("Client")
      expect(configuration.user_foreign_key).to eq("client_id")
    end

    it "accepts a singular symbol" do
      configuration = described_class.new

      configuration.owner_model = :account

      expect(configuration.user_class_name).to eq("Account")
      expect(configuration.user_foreign_key).to eq("account_id")
    end

    it "keeps an explicitly configured foreign key" do
      configuration = described_class.new

      configuration.owner_foreign_key = :member_id
      configuration.owner_model = :customers

      expect(configuration.user_class_name).to eq("Customer")
      expect(configuration.user_foreign_key).to eq("member_id")
    end

    it "keeps backward-compatible user_class_name assignment" do
      configuration = described_class.new

      configuration.user_class_name = "clients"

      expect(configuration.user_class_name).to eq("Client")
      expect(configuration.user_foreign_key).to eq("client_id")
    end
  end
end
