# frozen_string_literal: true

require "rails"

module RailsTablePreferences
  class Engine < ::Rails::Engine
    isolate_namespace RailsTablePreferences

    initializer "rails_table_preferences.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper RailsTablePreferences::TablePreferencesHelper if respond_to?(:helper)
      end
    end
  end
end
