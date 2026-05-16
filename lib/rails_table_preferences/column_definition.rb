# frozen_string_literal: true

module RailsTablePreferences
  class ColumnDefinition
    attr_reader :key,
                :label,
                :default_visible,
                :default_order,
                :default_width,
                :default_truncate,
                :pinned,
                :model,
                :model_name,
                :i18n_key

    def initialize(key:, label: nil, model: nil, model_name: nil, i18n_key: nil, default_visible: true, default_order: nil, default_width: nil, default_truncate: nil, pinned: false)
      @key = key.to_s
      @model = model
      @model_name = model_name
      @i18n_key = i18n_key
      @label = resolve_label(label)
      @default_visible = ActiveModel::Type::Boolean.new.cast(default_visible)
      @default_order = integer_or_nil(default_order)
      @default_width = integer_or_nil(default_width)
      @default_truncate = integer_or_nil(default_truncate)
      @pinned = ActiveModel::Type::Boolean.new.cast(pinned)
    end

    def to_h
      {
        "key" => key,
        "label" => label,
        "visible" => default_visible,
        "order" => default_order,
        "width" => default_width,
        "truncate" => default_truncate,
        "pinned" => pinned
      }.compact
    end

    private

    def resolve_label(explicit_label)
      return explicit_label if explicit_label.present?

      i18n_candidates.each do |candidate|
        translated = I18n.t(candidate, default: nil)
        return translated if translated.present?
      end

      key.humanize
    end

    def i18n_candidates
      candidates = []
      candidates << i18n_key.to_s if i18n_key.present?

      if normalized_model_name.present?
        candidates << "activerecord.attributes.#{normalized_model_name}.#{key}"
        candidates << "activemodel.attributes.#{normalized_model_name}.#{key}"
      end

      candidates << "attributes.#{key}"
      candidates
    end

    def normalized_model_name
      return model_name.to_s.underscore if model_name.present?

      if model.respond_to?(:model_name)
        model.model_name.i18n_key.to_s
      elsif model.present?
        model.to_s.underscore
      end
    end

    def integer_or_nil(value)
      return if value.blank?

      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
