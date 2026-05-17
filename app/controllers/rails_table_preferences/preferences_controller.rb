# frozen_string_literal: true

module RailsTablePreferences
  class PreferencesController < ApplicationController
    def index
      preferences = Preference.for_user(table_preferences_current_user)
                              .for_table(params[:table_key])
                              .order(default_flag: :desc, name: :asc)

      render json: {
        table_key: params[:table_key].to_s,
        preferences: preferences.map { |preference| preference_payload(preference) }
      }
    end

    def show
      preference = Preference.find_for(user: table_preferences_current_user, table_key: params[:table_key], name: preference_name)

      render json: preference_payload(preference)
    end

    def create
      preference = Preference.new(
        user: table_preferences_current_user,
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
        name: preference_name
      )
      preference.settings = SettingsNormalizer.call(settings_params)
      preference.default_flag = default_param? if params.key?(:default)
      clear_other_defaults(preference) if preference.default_flag?
      preference.save!

      render json: preference_payload(preference), status: :ok
    end

    def destroy
      preference = Preference.find_for(user: table_preferences_current_user, table_key: params[:table_key], name: preference_name)
      preference&.destroy!

      head :no_content
    end

    private

    def preference_name
      params[:name].presence || params[:preference_name].presence || "default"
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
      Preference.for_user(table_preferences_current_user)
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
        settings: settings
      }
    end
  end
end
