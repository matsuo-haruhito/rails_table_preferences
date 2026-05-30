# frozen_string_literal: true

module RailsTablePreferences
  class TableProfile
    class << self
      def inherited(subclass)
        subclass.instance_variable_set(:@model_class, @model_class)
        subclass.instance_variable_set(:@only_columns, duplicate_array(@only_columns))
        subclass.instance_variable_set(:@excluded_columns, duplicate_array(@excluded_columns))
        subclass.instance_variable_set(:@ordered_columns, duplicate_array(@ordered_columns))
        subclass.instance_variable_set(:@column_overrides, duplicate_hash(@column_overrides))
      end

      def model(value = nil)
        @model_class = value if value
        @model_class
      end

      def only(*keys)
        @only_columns = normalize_keys(keys)
      end

      def only_columns
        duplicate_array(@only_columns)
      end

      def exclude(*keys)
        @excluded_columns ||= []
        @excluded_columns |= normalize_keys(keys)
      end
      alias_method :except, :exclude

      def excluded_columns
        duplicate_array(@excluded_columns)
      end

      def order(*keys)
        @ordered_columns = normalize_keys(keys)
      end

      def ordered_columns
        duplicate_array(@ordered_columns)
      end

      def label(key, value)
        override(key, label: value)
      end

      def filter(key, value = nil, **options)
        override(key, filter: value || options)
      end

      def editor(key, value = nil, **options)
        override(key, editor: value || options)
      end

      def display(key, callable = nil, &block)
        override(key, formatter: callable || block)
      end
      alias_method :cell, :display

      def column(key, **attributes, &block)
        attributes[:formatter] = block if block
        override(key, **attributes)
      end

      def override(key, **attributes)
        @column_overrides ||= {}
        normalized_key = key.to_s
        existing = @column_overrides[normalized_key] || {}
        @column_overrides[normalized_key] = existing.merge(attributes.deep_stringify_keys)
      end

      def column_overrides
        duplicate_hash(@column_overrides)
      end

      def apply(columns)
        new.apply(columns)
      end

      private

      def normalize_keys(values)
        values.flatten.compact.map(&:to_s)
      end

      def duplicate_array(value)
        Array(value).map(&:dup)
      end

      def duplicate_hash(value)
        (value || {}).deep_dup
      end
    end

    def apply(columns)
      normalized = Array(columns).map { |column| RailsTablePreferences::Adapters::ColumnLike.call(column) }
      normalized = apply_overrides(normalized)
      normalized = append_virtual_columns(normalized)
      normalized = apply_order(normalized)
      normalized
    end

    private

    def apply_overrides(columns)
      overrides = self.class.column_overrides

      columns.map do |column|
        override = overrides[column.fetch("key").to_s]
        override ? column.merge(normalize_override(override)) : column
      end
    end

    def append_virtual_columns(columns)
      existing_keys = columns.map { |column| column.fetch("key").to_s }
      virtual_columns = virtual_keys.filter_map do |key|
        next if existing_keys.include?(key)

        RailsTablePreferences::Adapters::ColumnLike.call({ "key" => key }.merge(normalize_override(self.class.column_overrides.fetch(key))))
      end

      columns + virtual_columns
    end

    def virtual_keys
      only = self.class.only_columns
      excluded = self.class.excluded_columns
      override_keys = self.class.column_overrides.keys
      keys = only.empty? ? override_keys : only & override_keys
      keys - excluded
    end

    def apply_order(columns)
      order = self.class.ordered_columns
      return columns if order.empty?

      order_index = order.each_with_index.to_h
      columns.sort_by do |column|
        order_index.fetch(column.fetch("key").to_s, Float::INFINITY)
      end
    end

    def normalize_override(value)
      value.deep_stringify_keys.tap do |attributes|
        attributes["filter"] = attributes["filter"].to_table_filter if attributes["filter"].respond_to?(:to_table_filter)
        attributes["editor"] = attributes["editor"].to_table_cell_editor if attributes["editor"].respond_to?(:to_table_cell_editor)
      end
    end
  end
end
