# frozen_string_literal: true

module RailsTablePreferences
  module ColumnOptionsHelper
    def table_preferences_column(key, label: nil, model: nil, model_name: nil, i18n_key: nil, default_visible: true, default_order: nil, default_width: nil, default_truncate: nil, default_overflow: nil, overflow: nil, pinned: false, fixed: nil, group: nil, ignored: false, ignore: nil, filter: nil, sortable: nil, sort_param: nil)
      ColumnDefinition.new(
        key: key,
        label: label,
        model: model,
        model_name: model_name,
        i18n_key: i18n_key,
        default_visible: default_visible,
        default_order: default_order,
        default_width: default_width,
        default_truncate: default_truncate,
        default_overflow: default_overflow,
        overflow: overflow,
        pinned: pinned,
        fixed: fixed,
        group: group,
        ignored: ignored,
        ignore: ignore,
        filter: filter,
        sortable: sortable,
        sort_param: sort_param
      ).to_h
    end

    def table_preferences_column_groups(columns, ignored_columns: [])
      table_preferences_columns(columns, ignored_columns: ignored_columns)
        .group_by { |column| normalized_column_group(column) }
        .map do |group, grouped_columns|
          {
            "key" => group["key"],
            "label" => group["label"],
            "columns" => grouped_columns,
            "colspan" => grouped_columns.length
          }
        end
    end

    private

    def table_preferences_column_hash(column)
      RailsTablePreferences::Adapters::ColumnLike.call(column)
    end

    def normalized_column_group(column)
      group = column["group"] || column[:group]
      return { "key" => "", "label" => "" } if group.blank?

      case group
      when Hash
        stringified = group.deep_stringify_keys
        {
          "key" => stringified.fetch("key", stringified.fetch("label", "")).to_s,
          "label" => stringified.fetch("label", stringified.fetch("key", "")).to_s
        }
      else
        { "key" => group.to_s, "label" => group.to_s }
      end
    end
  end
end