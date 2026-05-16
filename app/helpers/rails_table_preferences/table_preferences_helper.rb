# frozen_string_literal: true

module RailsTablePreferences
  module TablePreferencesHelper
    def table_preferences_data_attributes(table_key:, name: "default", settings: nil)
      {
        controller: "rails-table-preferences",
        rails_table_preferences_table_key_value: table_key.to_s,
        rails_table_preferences_name_value: name.to_s,
        rails_table_preferences_url_value: table_preferences_preference_url(table_key: table_key, name: name),
        rails_table_preferences_settings_value: SettingsNormalizer.call(settings || {}).to_json
      }
    end

    def table_preferences_table_tag(table_key:, name: "default", settings: nil, **options, &block)
      options[:data] = (options[:data] || {}).merge(
        table_preferences_data_attributes(table_key: table_key, name: name, settings: settings)
      )

      tag.table(**options, &block)
    end

    def table_preferences_preference_url(table_key:, name: "default")
      mount_path = RailsTablePreferences.configuration.mount_path.to_s.chomp("/")
      encoded_table_key = ERB::Util.url_encode(table_key.to_s)
      encoded_name = ERB::Util.url_encode(name.to_s)

      "#{mount_path}/preferences/#{encoded_table_key}/#{encoded_name}"
    end
  end
end
