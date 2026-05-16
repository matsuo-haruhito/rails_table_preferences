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
      normalized["filters"] = normalize_hash(normalized["filters"])
      normalized["sorts"] = normalize_array(normalized["sorts"])
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
