# frozen_string_literal: true

module RailsTablePreferences
  class ValueResolver
    def self.call(record, column, view_context: nil)
      new(record, column, view_context: view_context).call
    end

    def initialize(record, column, view_context: nil)
      @record = record
      @column = column.respond_to?(:to_h) ? column.to_h.deep_stringify_keys : { "key" => column.to_s }
      @view_context = view_context
    end

    def call
      if formatter.respond_to?(:call)
        return call_formatter
      end

      value = raw_value
      format_value(value)
    end

    private

    attr_reader :record, :column, :view_context

    def key
      column.fetch("key").to_s
    end

    def formatter
      column["formatter"] || column["cell"]
    end

    def call_formatter
      arity = formatter.arity
      if arity == 1
        formatter.call(record)
      elsif arity == 2
        formatter.call(record, view_context)
      else
        formatter.call(record, column, view_context)
      end
    end

    def raw_value
      if record.respond_to?(key)
        record.public_send(key)
      elsif record.class.respond_to?(:reflect_on_association) && record.class.reflect_on_association(key.to_sym)
        record.public_send(key)
      end
    end

    def format_value(value)
      return "" if value.nil?
      return enum_label if enum_attribute?
      return localized_time(value) if time_like?(value)
      return boolean_label(value) if boolean_attribute?

      value
    end

    def enum_attribute?
      record.class.respond_to?(:defined_enums) && record.class.defined_enums.key?(key)
    end

    def enum_label
      i18n_method = "#{key}_i18n"
      return record.public_send(i18n_method) if record.respond_to?(i18n_method)

      record.public_send(key)
    end

    def boolean_attribute?
      record.class.respond_to?(:type_for_attribute) && record.class.type_for_attribute(key)&.type == :boolean
    end

    def boolean_label(value)
      I18n.t("rails_table_preferences.boolean.#{value ? "true" : "false"}", default: value ? "Yes" : "No")
    end

    def time_like?(value)
      value.respond_to?(:to_date) && (value.respond_to?(:hour) || value.class.name.match?(/Date|Time/))
    end

    def localized_time(value)
      return value unless view_context.respond_to?(:l)

      view_context.l(value)
    rescue I18n::ArgumentError
      value
    end
  end
end
