# frozen_string_literal: true

module RailsTablePreferences
  class PreferencesController < ApplicationController
    def index
      preferences = Preference.available_to(
        user: table_preferences_current_user,
        scope_context: table_preferences_scope_context
      ).for_table(params[:table_key])
       .order(default_flag: :desc, name: :asc)

      render json: {
        table_key: params[:table_key].to_s,
        preferences: preferences.map { |preference| preference_payload(preference) }
      }
    end

    def show
      preference = resolved_preference

      render json: preference_payload(preference)
    end

    def create
      preference = Preference.new(
        user: owner_for_write_scope,
        scope_type: scope_type_param,
        scope_key: scope_key_param,
        table_key: params[:table_key].to_s,
        name: preference_name,
        settings: SettingsNormalizer.call(settings_params),
        default_flag: default_param?
      )
      clear_other_defaults(preference) if preference.default_flag?
      preference.save!

      render json: preference_payload(preference), status: :created
    end

    def update
      preference = Preference.find_or_initialize_for(
        user: table_preferences_current_user,
        table_key: params[:table_key],
        name: preference_name,
        scope_type: scope_type_param,
        scope_key: scope_key_param
      )
      preference.user = owner_for_write_scope
      preference.scope_type = scope_type_param
      preference.scope_key = scope_key_param
      preference.settings = SettingsNormalizer.call(settings_params)
      preference.default_flag = default_param? if params.key?(:default)
      clear_other_defaults(preference) if preference.default_flag?
      preference.save!

      render json: preference_payload(preference), status: :ok
    end

    def destroy
      preference = Preference.find_for(
        user: table_preferences_current_user,
        table_key: params[:table_key],
        name: preference_name,
        scope_type: scope_type_param,
        scope_key: scope_key_param
      )
      preference&.destroy!

      head :no_content
    end

    private

    def resolved_preference
      return explicitly_scoped_preference if explicit_scope_param?
      return default_preference if preference_name == "default"

      Preference.available_named_preference(
        user: table_preferences_current_user,
        table_key: params[:table_key],
        name: preference_name,
        scope_context: table_preferences_scope_context
      )
    end

    def explicitly_scoped_preference
      Preference.find_for(
        user: table_preferences_current_user,
        table_key: params[:table_key],
        name: preference_name,
        scope_type: scope_type_param,
        scope_key: scope_key_param
      )
    end

    def default_preference
      Preference.default_for(
        user: table_preferences_current_user,
        table_key: params[:table_key],
        scope_context: table_preferences_scope_context
      )
    end

    def preference_name
      params[:name].presence || params[:preference_name].presence || "default"
    end

    def scope_type_param
      params[:scope_type].presence || Preference::OWNER_SCOPE_TYPE
    end

    def scope_key_param
      params[:scope_key].presence
    end

    def explicit_scope_param?
      params[:scope_type].present? || params[:scope_key].present?
    end

    def owner_for_write_scope
      scope_type_param == Preference::OWNER_SCOPE_TYPE ? table_preferences_current_user : nil
    end

    def default_param?
      return false unless params.key?(:default)

      ActiveModel::Type::Boolean.new.cast(params[:default])
    end

    def settings_params
      raw_settings = params[:settings]

      case raw_settings
      when ActionController::Parameters
        raw_settings.permit!.to_h
      when Hash
        raw_settings
      else
        {}
      end
    end

    def clear_other_defaults(preference)
      Preference.for_scope(preference.scope_type, preference.scope_key)
                .where(RailsTablePreferences.configuration.user_foreign_key => preference.user_id)
                .for_table(preference.table_key)
                .where.not(id: preference.id)
                .update_all(default_flag: false)
    end

    def preference_payload(preference)
      settings = preference&.settings || SettingsNormalizer.call({})

      {
        table_key: params[:table_key].to_s,
        name: preference&.name || preference_name,
        default: preference&.default_flag || false,
        scope_type: preference&.scope_type || scope_type_param,
        scope_key: preference&.scope_key,
        scope_label: preference&.scope_label || scope_type_param,
        editable: preference ? preference.editable_by_owner?(table_preferences_current_user) : true,
        settings: settings
      }
    end
  end
end
