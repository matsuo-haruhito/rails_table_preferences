# frozen_string_literal: true

module RailsTablePreferences
  module TablePreferencesHelper
    def table_preferences_column(key, label: nil, model: nil, model_name: nil, i18n_key: nil, default_visible: true, default_order: nil, default_width: nil, default_truncate: nil, pinned: false, fixed: nil, group: nil, ignored: false, ignore: nil, filter: nil, sortable: nil, sort_param: nil)
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

    private

    def table_preferences_column_hash(column)
      case column
      when ColumnDefinition
        column.to_h
      when Hash
        ColumnDefinition.new(
          key: column.fetch(:key, column["key"]),
          label: column.fetch(:label, column["label"]),
          model: column.fetch(:model, column["model"]),
          model_name: column.fetch(:model_name, column["model_name"]),
          i18n_key: column.fetch(:i18n_key, column["i18n_key"]),
          default_visible: column.fetch(:default_visible, column.fetch("default_visible", column.fetch(:visible, column.fetch("visible", true)))),
          default_order: column.fetch(:default_order, column.fetch("default_order", column.fetch(:order, column.fetch("order", nil)))),
          default_width: column.fetch(:default_width, column.fetch("default_width", column.fetch(:width, column.fetch("width", nil)))),
          default_truncate: column.fetch(:default_truncate, column.fetch("default_truncate", column.fetch(:truncate, column.fetch("truncate", nil)))),
          pinned: column.fetch(:pinned, column.fetch("pinned", false)),
          fixed: column.fetch(:fixed, column.fetch("fixed", nil)),
          group: column.fetch(:group, column.fetch("group", nil)),
          ignored: column.fetch(:ignored, column.fetch("ignored", false)),
          ignore: column.fetch(:ignore, column.fetch("ignore", nil)),
          filter: column.fetch(:filter, column.fetch("filter", nil)),
          sortable: column.fetch(:sortable, column.fetch("sortable", nil)),
          sort_param: column.fetch(:sort_param, column.fetch("sort_param", nil))
        ).to_h
      else
        table_preferences_column(column)
      end
    end
  end
end
