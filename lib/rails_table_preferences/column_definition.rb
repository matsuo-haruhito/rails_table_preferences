# frozen_string_literal: true

module RailsTablePreferences
  class ColumnDefinition
    OVERFLOW_ALIASES = {
      true => "ellipsis",
      false => nil,
      truncate: "ellipsis",
      truncated: "ellipsis",
      ellipsis: "ellipsis",
      clip: "clip",
      clipped: "clip",
      wrap: "wrap",
      wrapped: "wrap",
      nowrap: "nowrap",
      none: nil
    }.freeze

    attr_reader :key,
                :export_key,
                :label,
                :default_visible,
                :default_order,
                :default_width,
                :default_truncate,
                :default_overflow,
                :pinned,
                :group,
                :ignored,
                :filter,
                :editor,
                :sortable,
                :sort_param,
                :model,
                :model_name,
                :i18n_key

    def initialize(key:, export_key: nil, label: nil, model: nil, model_name: nil, i18n_key: nil, default_visible: true, default_order: nil, default_width: nil, default_truncate: nil, default_overflow: nil, overflow: nil, pinned: false, fixed: nil, group: nil, ignored: false, ignore: nil, filter: nil, editor: nil, sortable: nil, sort_param: nil)
      @key = key.to_s
      @export_key = export_key&.to_s.presence
      @model = model
      @model_name = model_name
      @i18n_key = i18n_key
      @label = resolve_label(label)
      @default_visible = ActiveModel::Type::Boolean.new.cast(default_visible)
      @default_order = integer_or_nil(default_order)
      @default_width = integer_or_nil(default_width)
      @default_truncate = integer_or_nil(default_truncate)
      @default_overflow = normalize_overflow(overflow.nil? ? default_overflow : overflow)
      @pinned = ActiveModel::Type::Boolean.new.cast(fixed.nil? ? pinned : fixed)
      @group = normalize_group(group)
      @ignored = ActiveModel::Type::Boolean.new.cast(ignore.nil? ? ignored : ignore) || label_unresolved?
      @filter = normalize_filter(filter)
      @editor = normalize_editor(editor)
      @sortable = normalize_sortable(sortable)
      @sort_param = sort_param&.to_s
    end

    def to_h
      {
        "key" => key,
        "export_key" => export_key,
        "label" => label,
        "visible" => default_visible,
        "order" => default_order,
        "width" => default_width,
        "truncate" => default_truncate,
        "overflow" => default_overflow,
        "pinned" => pinned,
        "group" => group,
        "ignored" => ignored,
        "filter" => filter,
        "editor" => editor,
        "sortable" => sortable,
        "sort_param" => sort_param
      }.compact
    end

    private

    def resolve_label(explicit_label)
      configured_label_resolution.each do |rule|
        resolved = resolve_label_rule(rule, explicit_label)
        return resolved if resolved.present?
      end

      resolve_unresolved_label
    end

    def resolve_label_rule(rule, explicit_label)
      case rule.to_sym
      when :label
        explicit_label
      when :i18n_key
        translate_i18n_key
      when :column_comment
        column_comment
      when :activerecord_attribute_i18n
        translate_model_attribute("activerecord")
      when :activemodel_attribute_i18n
        translate_model_attribute("activemodel")
      when :attribute_i18n
        translate("attributes.#{key}")
      when :humanize
        key.humanize
      when :key
        key
      end
    end

    def configured_label_resolution
      RailsTablePreferences.configuration.label_resolution
    end

    def resolve_unresolved_label
      case RailsTablePreferences.configuration.unresolved_label_behavior
      when :humanize
        key.humanize
      when :key
        key
      else
        nil
      end
    end

    def label_unresolved?
      label.blank? && RailsTablePreferences.configuration.unresolved_label_behavior == :hide
    end

    def translate_i18n_key
      return if i18n_key.blank?

      translate(i18n_key.to_s)
    end

    def translate_model_attribute(namespace)
      return if normalized_model_name.blank?

      translate("#{namespace}.attributes.#{normalized_model_name}.#{key}")
    end

    def translate(candidate)
      I18n.t(candidate, default: nil).presence
    end

    def column_comment
      return unless model.respond_to?(:columns_hash)

      column = model.columns_hash[key]
      return unless column.respond_to?(:comment)

      column.comment.presence
    end

    def normalized_model_name
      return model_name.to_s.underscore if model_name.present?

      if model.respond_to?(:model_name)
        model.model_name.i18n_key.to_s
      elsif model.present?
        model.to_s.underscore
      end
    end

    def normalize_group(value)
      case value
      when nil
        nil
      when Hash
        value.deep_stringify_keys.compact.tap do |attributes|
          attributes["key"] = attributes["key"].to_s if attributes["key"].present?
          attributes["label"] = attributes["label"].to_s if attributes["label"].present?
        end
      else
        { "key" => value.to_s, "label" => value.to_s }
      end
    end

    def normalize_filter(value)
      normalize_metadata(value, default_type: "text", option_normalizer: :normalize_filter_options)
    end

    def normalize_editor(value)
      normalized = value.to_table_cell_editor if value.respond_to?(:to_table_cell_editor)
      normalized ||= value

      normalize_metadata(normalized, default_type: "text")
    end

    def normalize_metadata(value, default_type:, option_normalizer: nil)
      case value
      when true
        { "type" => default_type }
      when false, nil
        nil
      when Symbol, String
        { "type" => value.to_s }
      when Hash
        normalize_metadata_hash(value, option_normalizer: option_normalizer)
      else
        nil
      end
    end

    def normalize_metadata_hash(value, option_normalizer: nil)
      value.deep_stringify_keys.compact.tap do |attributes|
        attributes["type"] = attributes["type"].to_s if attributes["type"].present?
        attributes["method"] = attributes["method"].to_s if attributes["method"].present?
        attributes["options"] = public_send(option_normalizer, attributes["options"]) if option_normalizer && attributes.key?("options")
      end
    end

    def normalize_filter_options(options)
      return options unless options.is_a?(Array)

      options.map do |option|
        case option
        when Hash
          option.deep_stringify_keys.compact.tap do |attributes|
            attributes["value"] = attributes["value"].to_s if attributes.key?("value")
            attributes["label"] = attributes["label"].to_s if attributes.key?("label")
          end
        else
          option
        end
      end
    end

    def normalize_sortable(value)
      return nil if value.nil?

      ActiveModel::Type::Boolean.new.cast(value)
    end

    def normalize_overflow(value)
      normalized = value.is_a?(String) || value.is_a?(Symbol) ? value.to_s.strip.downcase.to_sym : value
      OVERFLOW_ALIASES.fetch(normalized, nil)
    end

    def integer_or_nil(value)
      return if value.blank?

      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
