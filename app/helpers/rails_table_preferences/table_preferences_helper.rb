# frozen_string_literal: true

module RailsTablePreferences
  module TablePreferencesHelper
    def table_preferences_data_attributes(table_key:, name: "default", settings: nil, columns: [])
      {
        controller: "rails-table-preferences",
        rails_table_preferences_table_key_value: table_key.to_s,
        rails_table_preferences_name_value: name.to_s,
        rails_table_preferences_url_value: table_preferences_preference_url(table_key: table_key, name: name),
        rails_table_preferences_settings_value: SettingsNormalizer.call(settings || {}).to_json,
        rails_table_preferences_columns_value: table_preferences_columns(columns).to_json
      }
    end

    def table_preferences_table_tag(table_key:, name: "default", settings: nil, columns: [], **options, &block)
      options[:data] = (options[:data] || {}).merge(
        table_preferences_data_attributes(table_key: table_key, name: name, settings: settings, columns: columns)
      )

      tag.table(**options, &block)
    end

    def table_preferences_editor(table_key:, name: "default", settings: nil, columns: [], title: "Table settings")
      data_attributes = table_preferences_data_attributes(table_key: table_key, name: name, settings: settings, columns: columns)

      tag.div(data: data_attributes, class: "rails-table-preferences-editor") do
        safe_join(
          [
            tag.div(title, class: "rails-table-preferences-editor__title"),
            tag.div(data: { rails_table_preferences_target: "editorRows" }, class: "rails-table-preferences-editor__rows"),
            tag.div(class: "rails-table-preferences-editor__actions") do
              safe_join(
                [
                  tag.button("Apply", type: "button", data: { action: "rails-table-preferences#applyFromEditor" }),
                  tag.button("Save", type: "button", data: { action: "rails-table-preferences#saveFromEditor" }),
                  tag.button("Reset", type: "button", data: { action: "rails-table-preferences#resetEditor" })
                ],
                "\n"
              )
            end
          ],
          "\n"
        )
      end
    end

    def table_preferences_preference_url(table_key:, name: "default")
      mount_path = RailsTablePreferences.configuration.mount_path.to_s.chomp("/")
      encoded_table_key = ERB::Util.url_encode(table_key.to_s)
      encoded_name = ERB::Util.url_encode(name.to_s)

      "#{mount_path}/preferences/#{encoded_table_key}/#{encoded_name}"
    end

    def table_preferences_column(key, label: nil, default_visible: true, default_order: nil, default_width: nil, default_truncate: nil, pinned: false)
      ColumnDefinition.new(
        key: key,
        label: label,
        default_visible: default_visible,
        default_order: default_order,
        default_width: default_width,
        default_truncate: default_truncate,
        pinned: pinned
      ).to_h
    end

    def table_preferences_columns(columns)
      columns.map do |column|
        case column
        when ColumnDefinition
          column.to_h
        when Hash
          ColumnDefinition.new(
            key: column.fetch(:key, column["key"]),
            label: column.fetch(:label, column["label"]),
            default_visible: column.fetch(:default_visible, column.fetch("default_visible", column.fetch(:visible, column.fetch("visible", true)))),
            default_order: column.fetch(:default_order, column.fetch("default_order", column.fetch(:order, column.fetch("order", nil)))),
            default_width: column.fetch(:default_width, column.fetch("default_width", column.fetch(:width, column.fetch("width", nil)))),
            default_truncate: column.fetch(:default_truncate, column.fetch("default_truncate", column.fetch(:truncate, column.fetch("truncate", nil)))),
            pinned: column.fetch(:pinned, column.fetch("pinned", false))
          ).to_h
        else
          table_preferences_column(column)
        end
      end
    end
  end
end
