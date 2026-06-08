# frozen_string_literal: true

module RailsTablePreferences
  module TablePreferencesEditorHtmlOptionsHelper
    def table_preferences_editor(table_key:, name: "default", settings: nil, columns: [], ignored_columns: [], title: nil, partial: nil, editor_instance_key: nil, html_options: {})
      normalized_columns = table_preferences_columns(columns, ignored_columns: ignored_columns)
      normalized_settings = table_preferences_settings(settings, allowed_columns: normalized_columns)
      partial_name = partial.presence || RailsTablePreferences.configuration.editor_partial

      rendered = render partial: partial_name, locals: {
        table_key: table_key.to_s,
        name: name.to_s,
        title: title || I18n.t("rails_table_preferences.editor.title", default: "Table settings"),
        settings: normalized_settings,
        columns: normalized_columns,
        settings_json: normalized_settings.to_json,
        columns_json: normalized_columns.to_json,
        preference_url: table_preferences_preference_url(table_key: table_key, name: name),
        collection_url: table_preferences_collection_url(table_key: table_key),
        editor_instance_key: editor_instance_key,
        data_attributes: table_preferences_data_attributes(table_key: table_key, name: name, settings: normalized_settings, columns: normalized_columns)
      }

      table_preferences_editor_with_root_options(rendered, html_options)
    end

    private

    def table_preferences_editor_with_root_options(rendered, html_options)
      options = table_preferences_editor_root_options(html_options)
      return rendered if options.empty?

      html = rendered.to_s.dup
      host_class = options.delete(:class)

      if host_class.present?
        merged_class = class_names("rails-table-preferences-editor", host_class)
        unless html.sub!(/class="rails-table-preferences-editor"/, tag.attributes(class: merged_class).strip)
          if html.sub!(/\A(\s*<div\b[^>]*?)\sclass="([^"]*)"/) { "#{Regexp.last_match(1)} #{tag.attributes(class: class_names(Regexp.last_match(2), merged_class)).strip}" }
            options.delete(:class)
          else
            options[:class] = merged_class
          end
        end
      end

      attributes = tag.attributes(**options)
      html.sub!(/\A(\s*<div\b)/, "\\1 #{attributes}") if attributes.present?
      html.respond_to?(:html_safe) ? html.html_safe : html
    end

    def table_preferences_editor_root_options(html_options)
      options = (html_options || {}).deep_dup
      options = options.to_unsafe_h if options.respond_to?(:to_unsafe_h)
      options = options.to_h if options.respond_to?(:to_h)
      options = options.deep_symbolize_keys if options.respond_to?(:deep_symbolize_keys)

      host_class = options.delete(:class)

      host_data = options.delete(:data)
      data = table_preferences_editor_generic_data_attributes(host_data)

      options.reject! do |key, _value|
        key_name = key.to_s
        key_name == "data-controller" || key_name.start_with?("data-rails-table-preferences")
      end

      options[:class] = host_class if host_class.present?
      options[:data] = data if data.present?
      options
    end

    def table_preferences_editor_generic_data_attributes(data_attributes)
      data = (data_attributes || {}).deep_dup
      data = data.to_unsafe_h if data.respond_to?(:to_unsafe_h)
      data = data.to_h if data.respond_to?(:to_h)
      data = data.deep_symbolize_keys if data.respond_to?(:deep_symbolize_keys)

      data.reject do |key, _value|
        key_name = key.to_s
        key_name == "controller" ||
          key_name.start_with?("rails_table_preferences_") ||
          key_name.start_with?("rails-table-preferences-")
      end
    end
  end

  module TablePreferencesHelper
    prepend TablePreferencesEditorHtmlOptionsHelper
  end
end
