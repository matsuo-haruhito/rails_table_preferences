# frozen_string_literal: true

module RailsTablePreferences
  class ExportPayload
    def self.call(settings:, columns:, include_hidden: false)
      new(settings: settings, columns: columns, include_hidden: include_hidden).call
    end

    def initialize(settings:, columns:, include_hidden: false)
      @settings = SettingsNormalizer.call(settings || {})
      @columns = Array(columns).map { |column| normalize_column(column) }
      @include_hidden = ActiveModel::Type::Boolean.new.cast(include_hidden)
    end

    def call
      {
        "columns" => export_columns,
        "column_keys" => export_columns.map { |column| column["key"] },
        "export_keys" => export_columns.map { |column| column["export_key"] || column["key"] },
        "headers" => export_columns.map { |column| column["label"] || column["key"] },
        "settings" => settings
      }
    end

    private

    attr_reader :settings, :columns, :include_hidden

    def export_columns
      @export_columns ||= merged_columns
        .select { |column| include_hidden || column["visible"] != false }
        .sort_by { |column| order_value(column) }
    end

    def merged_columns
      saved_columns = settings.fetch("columns", []).index_by { |column| column["key"].to_s }

      columns.map do |column|
        saved_column = saved_columns[column["key"].to_s] || {}
        column.merge(saved_column).merge(
          "label" => column["label"],
          "group" => column["group"],
          "export_key" => column["export_key"] || column["key"]
        )
      end
    end

    def normalize_column(column)
      normalized = case column
      when ColumnDefinition
        column.to_h
      when Hash
        column.deep_stringify_keys
      else
        { "key" => column.to_s, "label" => column.to_s.humanize }
      end

      normalized["key"] = normalized.fetch("key").to_s
      normalized["label"] ||= normalized["key"].humanize
      normalized
    end

    def order_value(column)
      Integer(column["order"] || column[:order])
    rescue ArgumentError, TypeError
      Float::INFINITY
    end
  end
end
