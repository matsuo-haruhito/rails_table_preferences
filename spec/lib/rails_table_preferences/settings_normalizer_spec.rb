# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsTablePreferences::SettingsNormalizer do
  describe ".call" do
    it "drops non-positive column numeric settings" do
      settings = {
        columns: [
          { key: :name, order: -1, width: 0, truncate: -5 },
          { key: :email, display_order: 0, width: -20, truncate: 0 }
        ]
      }

      normalized = described_class.call(settings)

      expect(normalized["columns"]).to contain_exactly(
        { "key" => "name", "visible" => true, "pinned" => false },
        { "key" => "email", "visible" => true, "pinned" => false }
      )
    end

    it "keeps positive numeric strings as integers" do
      settings = {
        columns: [
          { key: :name, order: "10", width: "120", truncate: "40" }
        ]
      }

      normalized = described_class.call(settings)

      expect(normalized["columns"]).to contain_exactly(
        {
          "key" => "name",
          "visible" => true,
          "order" => 10,
          "width" => 120,
          "truncate" => 40,
          "pinned" => false
        }
      )
    end

    it "treats malformed column numeric settings as missing values" do
      settings = {
        columns: [
          { key: :name, order: "later", width: "wide", truncate: {} }
        ]
      }

      normalized = described_class.call(settings)

      expect(normalized["columns"]).to contain_exactly(
        { "key" => "name", "visible" => true, "pinned" => false }
      )
    end
  end
end
