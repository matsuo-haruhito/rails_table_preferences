# frozen_string_literal: true

module RailsTablePreferences
  class ColumnDefinition
    attr_reader :key, :label, :default_visible, :default_order, :default_width, :default_truncate, :pinned

    def initialize(key:, label: nil, default_visible: true, default_order: nil, default_width: nil, default_truncate: nil, pinned: false)
      @key = key.to_s
      @label = label.presence || key.to_s.humanize
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

    def integer_or_nil(value)
      return if value.blank?

      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
