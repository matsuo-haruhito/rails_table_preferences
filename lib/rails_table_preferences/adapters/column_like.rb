# frozen_string_literal: true

module RailsTablePreferences
  module Adapters
    class ColumnLike
      def self.call(column)
        new(column).call
      end

      def initialize(column)
        @column = column
      end

      def call
        case column
        when RailsTablePreferences::ColumnDefinition
          column.to_h
        when Hash
          build_from_hash(column)
        else
          build_from_object
        end
      end

      private

      attr_reader :column

      def build_from_object
        if column.respond_to?(:to_table_preference_column)
          build_from_hash(column.to_table_preference_column)
        elsif column.respond_to?(:to_h) && !column.is_a?(String) && !column.is_a?(Symbol)
          build_from_hash(column.to_h)
        else
          RailsTablePreferences::ColumnDefinition.new(key: column).to_h
        end
      end

      def build_from_hash(value)
        attributes = value.deep_stringify_keys

        RailsTablePreferences::ColumnDefinition.new(
          key: attributes.fetch("key"),
          label: attributes["label"],
          model: attributes["model"],
          model_name: attributes["model_name"],
          i18n_key: attributes["i18n_key"],
          default_visible: attributes.fetch("default_visible", attributes.fetch("visible", true)),
          default_order: attributes.fetch("default_order", attributes["order"]),
          default_width: attributes.fetch("default_width", attributes["width"]),
          default_truncate: attributes.fetch("default_truncate", attributes["truncate"]),
          default_overflow: attributes.fetch("default_overflow", attributes["overflow"]),
          overflow: attributes["overflow"],
          pinned: attributes.fetch("pinned", false),
          fixed: attributes["fixed"],
          group: attributes["group"],
          ignored: attributes.fetch("ignored", false),
          ignore: attributes["ignore"],
          filter: normalize_filter(attributes["filter"]),
          sortable: attributes["sortable"],
          sort_param: attributes["sort_param"]
        ).to_h.merge(extra_attributes(attributes))
      end

      def normalize_filter(value)
        if value.respond_to?(:to_table_filter)
          value.to_table_filter
        else
          value
        end
      end

      def extra_attributes(attributes)
        attributes.slice("export_key", "cell", "formatter", "editor")
      end
    end
  end
end