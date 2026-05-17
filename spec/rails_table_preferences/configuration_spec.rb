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

  describe "label resolution configuration" do
    it "defaults to explicit labels, explicit i18n keys, and database column comments" do
      configuration = described_class.new

      expect(configuration.label_resolution).to eq(%i[label i18n_key column_comment])
      expect(configuration.unresolved_label_behavior).to eq(:hide)
    end

    it "normalizes label resolution rule aliases" do
      configuration = described_class.new

      configuration.label_resolution = [
        :explicit_label,
        "explicit_i18n_key",
        :db_column_comment,
        :active_record_i18n,
        :active_model_i18n,
        :global_attribute_i18n,
        :humanize
      ]

      expect(configuration.label_resolution).to eq(
        %i[
          label
          i18n_key
          column_comment
          activerecord_attribute_i18n
          activemodel_attribute_i18n
          attribute_i18n
          humanize
        ]
      )
    end

    it "raises for unsupported label resolution rules" do
      configuration = described_class.new

      expect { configuration.label_resolution = [:label, :unknown_rule] }.to raise_error(
        ArgumentError,
        /Unsupported label resolution rule/
      )
    end

    it "normalizes unresolved label behavior aliases" do
      configuration = described_class.new

      configuration.unresolved_label_behavior = :ignore
      expect(configuration.unresolved_label_behavior).to eq(:hide)

      configuration.unresolved_label_behavior = "show_key"
      expect(configuration.unresolved_label_behavior).to eq(:key)
    end

    it "raises for unsupported unresolved label behaviors" do
      configuration = described_class.new

      expect { configuration.unresolved_label_behavior = :raise }.to raise_error(
        ArgumentError,
        /Unsupported unresolved label behavior/
      )
    end
  end
end