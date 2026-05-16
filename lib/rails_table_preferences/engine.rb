# frozen_string_literal: true

require "rails"

module RailsTablePreferences
  class Engine < ::Rails::Engine
    isolate_namespace RailsTablePreferences

    rake_tasks do
      load File.expand_path("../../tasks/rails_table_preferences.rake", __dir__)
    end

    initializer "rails_table_preferences.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper RailsTablePreferences::TablePreferencesHelper if respond_to?(:helper)
      end
    end
  end
end
