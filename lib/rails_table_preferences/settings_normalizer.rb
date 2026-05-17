# frozen_string_literal: true

module RailsTablePreferences
  class SettingsNormalizer
    DEFAULT_SETTINGS = {
      "columns" => [],
      "filters" => {},
      "sorts" => []
    }.freeze

    def self.call(settings)
      new(settings).call
    end

    def initialize(settings)
      @settings = settings
    end

    def call
      normalized = DEFAULT_SETTINGS.merge(normalize_hash(@settings))
      normalized["columns"] = normalize_columns(normalized["columns"])
      normalized["filters"] = normalize_filters(normalized["filters"])
      normalized["sorts"] = normalize_sorts(normalized["sorts"])
      normalized
    end

    private

    def normalize_hash(value)
      case value
      when Hash
        value.deep_stringify_keys
      else
        {}
      end
    end

    def normalize_array(value)
      value.is_a?(Array) ? value : []
    end

    def normalize_columns(value)
      normalize_array(value).filter_map do |column|
        normalize_column(column)
      end
    end

    def normalize_column(column)
      attributes = normalize_hash(column)
      key = attributes["key"].presence || attributes["column_name"].presence
      return if key.blank?

      {
        "key" => key.to_s,
        "visible" => boolean_value(attributes.fetch("visible", attributes.fetch("display_flag", true))),
        "order" => integer_value(attributes.fetch("order", attributes.fetch("display_order", nil))),
        "width" => integer_value(attributes["width"]),
        "truncate" => integer_value(attributes["truncate"]),
        "pinned" => boolean_value(attributes.fetch("pinned", false))
      }.compact
    end

    def normalize_filters(value)
      normalize_hash(value).each_with_object({}) do |(key, condition), filters|
        normalized = normalize_filter_condition(condition)
        filters[key.to_s] = normalized if normalized.present?
      end
    end

    def normalize_filter_condition(condition)
      attributes = normalize_hash(condition)
      operator = attributes["operator"].presence || attributes["predicate"].presence
      return if operator.blank?

      normalized = {
        "operator" => operator.to_s,
        "value" => attributes["value"],
        "values" => normalize_values(attributes["values"]),
        "from" => attributes["from"],
        "to" => attributes["to"]
      }.compact

      normalized.delete("values") if normalized["values"].blank?
      normalized
    end

    def normalize_values(value)
      case value
      when Array
        value
      when nil
        nil
      else
        [value]
      end
    end

    def normalize_sorts(value)
      normalize_array(value).filter_map do |sort|
        normalize_sort(sort)
      end
    end

    def normalize_sort(sort)
      attributes = normalize_hash(sort)
      key = attributes["key"].presence || attributes["column"].presence
      direction = attributes["direction"].presence || attributes["dir"].presence
      return if key.blank? || direction.blank?

      normalized_direction = direction.to_s.downcase
      return unless %w[asc desc].include?(normalized_direction)

      {
        "key" => key.to_s,
        "direction" => normalized_direction
      }
    end

    def boolean_value(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    def integer_value(value)
      return if value.blank?

      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
