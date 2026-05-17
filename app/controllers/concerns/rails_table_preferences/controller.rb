# frozen_string_literal: true

module RailsTablePreferences
  module Controller
    extend ActiveSupport::Concern

    # Returns the saved preference for the given table.
    #
    # Resolution rule:
    # - explicit name: use that preset name
    # - no name: use default_flag=true first
    # - fallback: use name="default"
    # - missing preference: return nil
    def rails_table_preference(table_key:, name: nil, owner: nil)
      owner ||= rails_table_preferences_current_owner
      return unless owner

      scope = RailsTablePreferences::Preference.for_user(owner).for_table(table_key)
      return scope.find_by(name: name.to_s) if name.present?

      scope.defaults.order(:name).first || scope.find_by(name: "default")
    end

    def rails_table_preference_settings(table_key:, name: nil, owner: nil, fallback: {})
      preference = rails_table_preference(table_key: table_key, name: name, owner: owner)
      RailsTablePreferences::SettingsNormalizer.call(preference&.settings || fallback || {})
    end

    # Converts saved table preference filters/sorts into params for the host app.
    #
    # adapter: :controller_params returns a plain params hash suitable for existing
    #   search(params) / order_by(params[:sort]) style controllers.
    # adapter: :ransack returns Ransack-compatible params.
    def rails_table_preference_params(table_key:, columns:, name: nil, owner: nil, adapter: :controller_params, sort_param: "sort")
      settings = rails_table_preference_settings(table_key: table_key, name: name, owner: owner)
      rails_table_preference_adapter_params(
        adapter: adapter,
        settings: settings,
        columns: columns,
        sort_param: sort_param
      )
    end

    # Convenience method for apps that want to merge saved preference filters into
    # the current controller params before passing them to a model search method.
    def rails_table_preference_merged_params(params_source = params, **options)
      base_params = rails_table_preferences_hash_from_params(params_source)
      base_params.merge(rails_table_preference_params(**options))
    end

    private

    def rails_table_preference_adapter_params(adapter:, settings:, columns:, sort_param:)
      case adapter.to_sym
      when :controller_params, :plain_params, :params
        RailsTablePreferences::Adapters::ControllerParams.to_params(
          filters: settings["filters"],
          sorts: settings["sorts"],
          columns: columns,
          sort_param: sort_param
        )
      when :ransack
        RailsTablePreferences::Adapters::Ransack.to_params(
          filters: settings["filters"],
          sorts: settings["sorts"]
        )
      else
        raise ArgumentError, "Unsupported table preference adapter: #{adapter.inspect}"
      end
    end

    def rails_table_preferences_current_owner
      send(RailsTablePreferences.configuration.current_user_method)
    end

    def rails_table_preferences_hash_from_params(params_source)
      case params_source
      when ActionController::Parameters
        params_source.to_unsafe_h
      when Hash
        params_source.stringify_keys
      else
        {}
      end
    end
  end
end
