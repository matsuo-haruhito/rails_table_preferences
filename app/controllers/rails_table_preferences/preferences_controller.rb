# frozen_string_literal: true

module RailsTablePreferences
  class PreferencesController < ApplicationController
    def show
      preference = Preference.find_for(user: table_preferences_current_user, table_key: params[:table_key], name: preference_name)

      render json: preference_payload(preference)
    end

    def update
      preference = Preference.find_or_initialize_for(
        user: table_preferences_current_user,
        table_key: params[:table_key],
        name: preference_name
      )
      preference.settings = SettingsNormalizer.call(settings_params)
      preference.default_flag = ActiveModel::Type::Boolean.new.cast(params[:default]) if params.key?(:default)
      preference.save!

      render json: preference_payload(preference), status: :ok
    end

    private

    def preference_name
      params[:name].presence || "default"
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

    def preference_payload(preference)
      settings = preference&.settings || SettingsNormalizer.call({})

      {
        table_key: params[:table_key].to_s,
        name: preference&.name || preference_name,
        default: preference&.default_flag || false,
        settings: settings
      }
    end
  end
end
