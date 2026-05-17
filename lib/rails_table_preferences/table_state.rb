# frozen_string_literal: true

module RailsTablePreferences
  class TableState
    def self.call(settings:, columns:, include_hidden: false)
      new(settings: settings, columns: columns, include_hidden: include_hidden).call
    end

    def initialize(settings:, columns:, include_hidden: false)
      @settings = SettingsNormalizer.call(settings || {})
      @columns = Array(columns).map { |column| RailsTablePreferences::Adapters::ColumnLike.call(column) }
      @include_hidden = ActiveModel::Type::Boolean.new.cast(include_hidden)
    end

    def call
      {
        "columns" => resolved_columns,
        "visible_columns" => visible_columns,
        "hidden_columns" => hidden_columns,
        "column_keys" => visible_columns.map { |column| column["key"] },
        "headers" => visible_columns.map { |column| column["label"] || column["key"] },
        "filters" => settings.fetch("filters", {}),
        "sorts" => settings.fetch("sorts", []),
        "settings" => settings
      }
    end

    private

    attr_reader :settings, :columns, :include_hidden

    def resolved_columns
      @resolved_columns ||= merged_columns
        .select { |column| include_hidden || column["visible"] != false }
        .sort_by { |column| order_value(column) }
    end

    def visible_columns
      @visible_columns ||= resolved_columns.select { |column| column["visible"] != false }
    end

    def hidden_columns
      @hidden_columns ||= merged_columns.select { |column| column["visible"] == false }
    end

    def merged_columns
      saved_columns = settings.fetch("columns", []).index_by { |column| column["key"].to_s }

      columns.map do |column|
        saved_column = saved_columns[column["key"].to_s] || {}
        column.merge(saved_column).merge(
          "label" => column["label"],
          "group" => column["group"],
          "filter" => column["filter"],
          "sortable" => column["sortable"],
          "export_key" => column["export_key"] || column["key"]
        )
      end
    end

    def order_value(column)
      Integer(column["order"] || column[:order])
    rescue ArgumentError, TypeError
      Float::INFINITY
    end
  end
end
