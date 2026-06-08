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

    it "normalizes filter aliases while preserving false and zero values" do
      settings = {
        filters: {
          active: { predicate: :eq, value: false },
          score: { operator: "gteq", values: 0 },
          created_on: { operator: "between", from: "2026-01-01", to: "2026-01-31" }
        }
      }

      normalized = described_class.call(settings)

      expect(normalized["filters"]).to eq(
        "active" => { "operator" => "eq", "value" => false },
        "score" => { "operator" => "gteq", "values" => [0] },
        "created_on" => { "operator" => "between", "from" => "2026-01-01", "to" => "2026-01-31" }
      )
    end

    it "keeps array filter values and drops empty value arrays" do
      settings = {
        filters: {
          status: { operator: :in, values: %w[draft published] },
          category: { operator: :in, values: [] }
        }
      }

      normalized = described_class.call(settings)

      expect(normalized["filters"]).to eq(
        "status" => { "operator" => "in", "values" => %w[draft published] },
        "category" => { "operator" => "in" }
      )
    end

    it "normalizes sort aliases and drops unsupported directions" do
      settings = {
        sorts: [
          { column: :published_at, dir: :DESC },
          { key: :title, direction: "asc" },
          { key: :ignored, direction: "sideways" },
          { column: :missing_direction }
        ]
      }

      normalized = described_class.call(settings)

      expect(normalized["sorts"]).to eq(
        [
          { "key" => "published_at", "direction" => "desc" },
          { "key" => "title", "direction" => "asc" }
        ]
      )
    end
  end
end
