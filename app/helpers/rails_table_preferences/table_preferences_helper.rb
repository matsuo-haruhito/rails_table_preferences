# frozen_string_literal: true

module RailsTablePreferences
  module TablePreferencesHelper
    def table_preferences_data_attributes(table_key:, name: "default", settings: nil)
      {
        controller: "rails-table-preferences",
        rails_table_preferences_table_key_value: table_key.to_s,
        rails_table_preferences_name_value: name.to_s,
        rails_table_preferences_url_value: preference_path(table_key: table_key, name: name),
        rails_table_preferences_settings_value: SettingsNormalizer.call(settings || {}).to_json
      }
    end

    def table_preferences_table_tag(table_key:, name: "default", settings: nil, **options, &block)
      options[:data] = (options[:data] || {}).merge(
        table_preferences_data_attributes(table_key: table_key, name: name, settings: settings)
      )

      tag.table(**options, &block)
    end
  end
end
