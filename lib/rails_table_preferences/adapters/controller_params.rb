# frozen_string_literal: true

module RailsTablePreferences
  module Adapters
    module ControllerParams
      module_function

      DEFAULT_SORT_PARAM = "sort"
      DESC_PREFIX = "-"

      # Converts neutral Rails Table Preferences filters/sorts into a plain hash
      # suitable for existing Rails controllers that call search(params) and
      # order_by(params[:sort]).
      #
      # This adapter intentionally does not execute queries.
      def to_params(filters: {}, sorts: [], columns: [], sort_param: DEFAULT_SORT_PARAM)
        filter_params(filters: filters, columns: columns).merge(
          sort_params(sorts: sorts, columns: columns, sort_param: sort_param)
        )
      end

      def filter_params(filters: {}, columns: [])
        column_map = column_map(columns)

        stringify_keys(filters).each_with_object({}) do |(key, condition), params|
          normalized = stringify_keys(condition || {})
          operator = normalized["operator"].to_s
          next if blank?(operator)

          metadata = column_map[key.to_s] || {}
          filter_metadata = stringify_keys(metadata["filter"] || {})
          param_base = filter_metadata["param"].presence || key.to_s

          case operator
          when "between"
            assign_value(params, filter_metadata["from_param"].presence || "from_#{param_base}", normalized["from"])
            assign_value(params, filter_metadata["to_param"].presence || "to_#{param_base}", normalized["to"])
          when "gteq", "gt"
            assign_value(params, filter_metadata["from_param"].presence || "from_#{param_base}", normalized["value"])
          when "lteq", "lt"
            assign_value(params, filter_metadata["to_param"].presence || "to_#{param_base}", normalized["value"])
          when "in", "not_in"
            values_param = filter_metadata["values_param"].presence || param_base
            assign_value(params, values_param, array_value(normalized["values"] || normalized["value"]))
          when "blank", "present", "true", "false"
            assign_value(params, filter_metadata["operator_param"].presence || "#{param_base}_operator", operator)
          else
            assign_value(params, param_base, normalized["value"])
            assign_value(params, filter_metadata["operator_param"], operator) if filter_metadata["operator_param"].present?
          end
        end
      end

      def sort_params(sorts: [], columns: [], sort_param: DEFAULT_SORT_PARAM)
        column_map = column_map(columns)
        sort = Array(sorts).filter_map do |sort_entry|
          normalized = stringify_keys(sort_entry || {})
          key = normalized["key"].presence || normalized["column"].presence
          direction = normalized["direction"].presence || normalized["dir"].presence
          next if blank?(key) || blank?(direction)

          direction = direction.to_s.downcase
          next unless %w[asc desc].include?(direction)

          metadata = column_map[key.to_s] || {}
          sort_key = stringify_keys(metadata)["sort_param"].presence || key.to_s
          direction == "desc" ? "#{DESC_PREFIX}#{sort_key}" : sort_key
        end.first

        sort.present? ? { sort_param.to_s => sort } : {}
      end

      def column_map(columns)
        Array(columns).each_with_object({}) do |column, map|
          normalized = stringify_keys(column || {})
          key = normalized["key"]
          map[key.to_s] = normalized if key.present?
        end
      end

      def assign_value(params, key, value)
        return if blank?(key) || blank?(value)

        params[key.to_s] = value
      end

      def array_value(value)
        case value
        when Array
          value.reject { |item| blank?(item) }
        when nil
          []
        else
          [value]
        end
      end

      def blank?(value)
        return true if value.nil?
        return value.blank? if value.respond_to?(:blank?)
        return value.empty? if value.respond_to?(:empty?)

        false
      end

      def stringify_keys(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, child), hash|
            hash[key.to_s] = stringify_keys(child)
          end
        when Array
          value.map { |child| stringify_keys(child) }
        else
          value
        end
      end
    end
  end
end
