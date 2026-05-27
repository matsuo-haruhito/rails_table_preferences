# frozen_string_literal: true

require "rails"

module RailsTablePreferences
  class Engine < ::Rails::Engine
    isolate_namespace RailsTablePreferences

    rake_tasks do
      load File.expand_path("../tasks/rails_table_preferences.rake", __dir__)
    end

    initializer "rails_table_preferences.load_controller_extensions" do
      require_dependency root.join("app/helpers/rails_table_preferences/table_preferences_helper").to_s
      require_dependency root.join("app/helpers/rails_table_preferences/column_options_helper").to_s
      require_dependency root.join("app/controllers/concerns/rails_table_preferences/controller").to_s
    end

    initializer "rails_table_preferences.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper RailsTablePreferences::TablePreferencesHelper if respond_to?(:helper)
        helper RailsTablePreferences::ColumnOptionsHelper if respond_to?(:helper)
        include RailsTablePreferences::Controller
      end
    end
  end
end
