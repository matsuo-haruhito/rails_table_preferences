# frozen_string_literal: true

module RailsTablePreferences
  module Adapters
    module Ransack
      module_function

      PREDICATES = {
        "contains" => "cont",
        "not_contains" => "not_cont",
        "equals" => "eq",
        "not_equals" => "not_eq",
        "starts_with" => "start",
        "ends_with" => "end",
        "in" => "in",
        "not_in" => "not_in",
        "gt" => "gt",
        "gteq" => "gteq",
        "lt" => "lt",
        "lteq" => "lteq",
        "blank" => "blank",
        "present" => "present",
        "true" => "true",
        "false" => "false"
      }.freeze

      SORT_DIRECTIONS = {
        "asc" => "asc",
        "desc" => "desc"
      }.freeze

      def to_params(filters: {}, sorts: [])
        filter_params(filters).merge(sort_params(sorts))
      end

      def filter_params(filters)
        filters.each_with_object({}) do |(key, condition), params|
          normalized = normalize_condition(condition)
          predicate = predicate_for(normalized["operator"])
          next unless predicate

          param_key = "#{key}_#{predicate}"
          value = value_for(normalized)
          params[param_key] = value unless skip_value?(predicate, value)
        end
      end

      def sort_params(sorts)
        values = Array(sorts).filter_map do |sort|
          normalized = stringify_keys(sort)
          key = normalized["key"]
          direction = SORT_DIRECTIONS[normalized["direction"].to_s]
          next if blank?(key) || blank?(direction)

          "#{key} #{direction}"
        end

        values.empty? ? {} : { "s" => values }
      end

      def normalize_condition(condition)
        stringify_keys(condition || {})
      end

      def predicate_for(operator)
        PREDICATES[operator.to_s]
      end

      def value_for(condition)
        operator = condition["operator"].to_s

        case operator
        when "in", "not_in"
          condition["values"] || condition["value"] || []
        when "blank", "present", "true", "false"
          true
        else
          condition["value"]
        end
      end

      def skip_value?(predicate, value)
        return false if %w[blank present true false].include?(predicate)

        blank?(value)
      end

      def blank?(value)
        return true if value.nil?
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
