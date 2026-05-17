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

    def resource_table_for(records, model: nil, table_key: nil, name: "default", settings: nil, only: nil, except: nil, include_id: false, include_associations: true, profile: nil, partial: nil, **options)
      model ||= table_preferences_model_for(records, profile: profile)
      table_key ||= model.model_name.route_key
      columns = table_preferences_resource_columns(
        model: model,
        only: only,
        except: except,
        include_id: include_id,
        include_associations: include_associations,
        profile: profile
      )
      table_state = table_preferences_state(settings: settings, columns: columns)

      render partial: partial.presence || RailsTablePreferences.configuration.resource_table_partial, locals: {
        records: records,
        model: model,
        table_key: table_key.to_s,
        name: name.to_s,
        settings: table_preferences_settings(settings, allowed_columns: columns),
        columns: columns,
        table_state: table_state,
        profile: profile,
        options: options
      }
    end

    def tree_resource_table_for(records, model: nil, table_key: nil, parent_id_method: :parent_id, name: "default", settings: nil, only: nil, except: nil, include_id: false, include_associations: true, profile: nil, partial: nil, **options)
      model ||= table_preferences_model_for(records, profile: profile)
      table_key ||= "#{model.model_name.route_key}_tree"
      columns = table_preferences_resource_columns(
        model: model,
        only: only,
        except: except,
        include_id: include_id,
        include_associations: include_associations,
        profile: profile
      )
      table_state = table_preferences_state(settings: settings, columns: columns)

      render partial: partial.presence || RailsTablePreferences.configuration.tree_resource_table_partial, locals: {
        records: records,
        model: model,
        table_key: table_key.to_s,
        parent_id_method: parent_id_method,
        name: name.to_s,
        settings: table_preferences_settings(settings, allowed_columns: columns),
        columns: columns,
        table_state: table_state,
        profile: profile,
        options: options
      }
    end

    def table_preferences_state(settings:, columns:, ignored_columns: [], include_hidden: false)
      normalized_columns = table_preferences_columns(columns, ignored_columns: ignored_columns)
      normalized_settings = table_preferences_settings(settings, allowed_columns: normalized_columns)

      RailsTablePreferences::TableState.call(
        settings: normalized_settings,
        columns: normalized_columns,
        include_hidden: include_hidden
      )
    end

    def table_preferences_value(record, column)
      RailsTablePreferences::ValueResolver.call(record, column, view_context: self)
    end

    def table_preferences_filter_input(form:, column:, method: nil, fallback: nil)
      filter = table_preferences_filter_metadata(column)
      return fallback unless filter

      type = filter.fetch("type", nil)
      rendered = RailsTablePreferences.configuration.filter_renderers.call(
        type,
        form: form,
        method: method || filter["method"] || column["key"],
        filter: filter,
        column: column,
        view_context: self
      )
      rendered || fallback
    end

    def table_preferences_cell_editor(form:, record:, column:, method: nil, fallback: nil)
      editor = table_preferences_editor_metadata(column)
      return fallback unless editor

      type = editor.fetch("type", nil)
      rendered = RailsTablePreferences.configuration.editor_renderers.call(
        type,
        form: form,
        record: record,
        method: method || editor["method"] || column["key"],
        editor: editor,
        column: column,
        view_context: self
      )
      rendered || fallback
    end

    def table_preferences_preference_url(table_key:, name: "default")
      "#{table_preferences_collection_url(table_key: table_key)}/#{ERB::Util.url_encode(name.to_s)}"
    end

    def table_preferences_collection_url(table_key:)
      mount_path = RailsTablePreferences.configuration.mount_path.to_s.chomp("/")
      encoded_table_key = ERB::Util.url_encode(table_key.to_s)

      "#{mount_path}/preferences/#{encoded_table_key}"
    end

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

    def table_preferences_params(settings:, columns:, ignored_columns: [], adapter: :controller_params, sort_param: "sort")
      normalized_columns = table_preferences_columns(columns, ignored_columns: ignored_columns)
      normalized_settings = table_preferences_settings(settings, allowed_columns: normalized_columns)

      case adapter.to_sym
      when :controller_params, :plain_params, :params
        RailsTablePreferences::Adapters::ControllerParams.to_params(
          filters: normalized_settings["filters"],
          sorts: normalized_settings["sorts"],
          columns: normalized_columns,
          sort_param: sort_param
        )
      when :ransack
        RailsTablePreferences::Adapters::Ransack.to_params(
          filters: normalized_settings["filters"],
          sorts: normalized_settings["sorts"]
        )
      else
        raise ArgumentError, "Unsupported table preference adapter: #{adapter.inspect}"
      end
    end

    def table_preferences_hidden_fields(settings:, columns:, ignored_columns: [], adapter: :controller_params, sort_param: "sort", namespace: nil)
      params_hash = table_preferences_params(
        settings: settings,
        columns: columns,
        ignored_columns: ignored_columns,
        adapter: adapter,
        sort_param: sort_param
      )

      safe_join(table_preferences_hidden_field_tags(params_hash, namespace: namespace))
    end

    private

    def table_preferences_model_for(records, profile: nil)
      return profile.model if profile.respond_to?(:model) && profile.model
      return records.klass if records.respond_to?(:klass)
      first_record = records.respond_to?(:first) ? records.first : nil
      return first_record.class if first_record

      raise ArgumentError, "model: is required when records do not expose klass and are empty"
    end

    def table_preferences_resource_columns(model:, only:, except:, include_id:, include_associations:, profile:)
      profile_class = table_preferences_profile_class(profile)
      resolved_only = only || profile_class&.only_columns
      resolved_except = Array(except) | Array(profile_class&.excluded_columns)
      columns = RailsTablePreferences::Adapters::ActiveRecordColumns.call(
        model: model,
        only: resolved_only,
        except: resolved_except,
        include_id: include_id,
        include_associations: include_associations
      )

      profile_class ? profile_class.apply(columns) : columns
    end

    def table_preferences_profile_class(profile)
      return if profile.nil?
      return profile.class unless profile.is_a?(Class)

      profile
    end

    def table_preferences_filter_metadata(column)
      filter = column["filter"] || column[:filter]
      filter = filter.to_table_filter if filter.respond_to?(:to_table_filter)
      filter.respond_to?(:to_h) ? filter.to_h.deep_stringify_keys : filter
    end

    def table_preferences_editor_metadata(column)
      editor = column["editor"] || column[:editor]
      editor = editor.to_table_cell_editor if editor.respond_to?(:to_table_cell_editor)
      editor.respond_to?(:to_h) ? editor.to_h.deep_stringify_keys : editor
    end

    def table_preferences_column_hash(column)
      RailsTablePreferences::Adapters::ColumnLike.call(column)
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
          default_overflow: column.fetch(:default_overflow, column.fetch("default_overflow", column.fetch(:overflow, column.fetch("overflow", nil)))),
          pinned: column.fetch(:pinned, column.fetch("pinned", false)),
          fixed: column.fetch(:fixed, column.fetch("fixed", nil)),
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

    def table_preferences_hidden_field_tags(params_hash, namespace: nil, prefix: nil)
      params_hash.flat_map do |key, value|
        field_name = table_preferences_field_name(key, namespace: namespace, prefix: prefix)

        case value
        when Hash
          table_preferences_hidden_field_tags(value, namespace: nil, prefix: field_name)
        when Array
          value.reject(&:blank?).map do |item|
            hidden_field_tag("#{field_name}[]", item, id: nil)
          end
        else
          value.blank? ? [] : hidden_field_tag(field_name, value, id: nil)
        end
      end
    end

    def table_preferences_field_name(key, namespace: nil, prefix: nil)
      key = key.to_s
      return "#{prefix}[#{key}]" if prefix.present?
      return "#{namespace}[#{key}]" if namespace.present?

      key
    end
  end
end
