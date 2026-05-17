# frozen_string_literal: true

require "set"

module RailsTablePreferences
  module TablePreferencesHelper
    def table_preferences_data_attributes(table_key:, name: "default", settings: nil, columns: [], ignored_columns: [])
      normalized_columns = table_preferences_columns(columns, ignored_columns: ignored_columns)
      normalized_settings = table_preferences_settings(settings, allowed_columns: normalized_columns)

      {
        controller: "rails-table-preferences",
        rails_table_preferences_table_key_value: table_key.to_s,
        rails_table_preferences_name_value: name.to_s,
        rails_table_preferences_url_value: table_preferences_preference_url(table_key: table_key, name: name),
        rails_table_preferences_collection_url_value: table_preferences_collection_url(table_key: table_key),
        rails_table_preferences_settings_value: normalized_settings.to_json,
        rails_table_preferences_columns_value: normalized_columns.to_json
      }
    end

    def table_preferences_table_tag(table_key:, name: "default", settings: nil, columns: [], ignored_columns: [], **options, &block)
      options[:data] = (options[:data] || {}).merge(
        table_preferences_data_attributes(table_key: table_key, name: name, settings: settings, columns: columns, ignored_columns: ignored_columns)
      )

      tag.table(**options, &block)
    end

    def table_preferences_editor(table_key:, name: "default", settings: nil, columns: [], ignored_columns: [], title: nil, partial: nil)
      normalized_columns = table_preferences_columns(columns, ignored_columns: ignored_columns)
      normalized_settings = table_preferences_settings(settings, allowed_columns: normalized_columns)
      partial_name = partial.presence || RailsTablePreferences.configuration.editor_partial

      render partial: partial_name, locals: {
        table_key: table_key.to_s,
        name: name.to_s,
        title: title || I18n.t("rails_table_preferences.editor.title", default: "Table settings"),
        settings: normalized_settings,
        columns: normalized_columns,
        settings_json: normalized_settings.to_json,
        columns_json: normalized_columns.to_json,
        preference_url: table_preferences_preference_url(table_key: table_key, name: name),
        collection_url: table_preferences_collection_url(table_key: table_key),
        data_attributes: table_preferences_data_attributes(table_key: table_key, name: name, settings: normalized_settings, columns: normalized_columns)
      }
    end

    def table_preferences_preference_url(table_key:, name: "default")
      "#{table_preferences_collection_url(table_key: table_key)}/#{ERB::Util.url_encode(name.to_s)}"
    end

    def table_preferences_collection_url(table_key:)
      mount_path = RailsTablePreferences.configuration.mount_path.to_s.chomp("/")
      encoded_table_key = ERB::Util.url_encode(table_key.to_s)

      "#{mount_path}/preferences/#{encoded_table_key}"
    end

    def table_preferences_column(key, label: nil, model: nil, model_name: nil, i18n_key: nil, default_visible: true, default_order: nil, default_width: nil, default_truncate: nil, pinned: false, ignored: false, ignore: nil, filter: nil, sortable: nil)
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
        ignored: ignored,
        ignore: ignore,
        filter: filter,
        sortable: sortable
      ).to_h
    end

    def table_preferences_columns(columns, ignored_columns: [])
      ignored_keys = Array(ignored_columns).map(&:to_s).to_set

      columns.filter_map do |column|
        normalized = table_preferences_column_hash(column)
        next if normalized["ignored"] == true
        next if ignored_keys.include?(normalized["key"].to_s)

        normalized.except("ignored")
      end
    end

    def table_preferences_settings(settings, allowed_columns: nil)
      normalized_settings = SettingsNormalizer.call(settings || {})
      return normalized_settings unless allowed_columns

      allowed_keys = allowed_columns.map { |column| column["key"].to_s }.to_set
      normalized_settings.merge(
        "columns" => normalized_settings.fetch("columns", []).select { |column| allowed_keys.include?(column["key"].to_s) },
        "filters" => normalized_settings.fetch("filters", {}).select { |key, _condition| allowed_keys.include?(key.to_s) },
        "sorts" => normalized_settings.fetch("sorts", []).select { |sort| allowed_keys.include?(sort["key"].to_s) }
      )
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
          ignored: column.fetch(:ignored, column.fetch("ignored", false)),
          ignore: column.fetch(:ignore, column.fetch("ignore", nil)),
          filter: column.fetch(:filter, column.fetch("filter", nil)),
          sortable: column.fetch(:sortable, column.fetch("sortable", nil))
        ).to_h
      else
        table_preferences_column(column)
      end
    end
  end
end
