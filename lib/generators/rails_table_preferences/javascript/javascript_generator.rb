# frozen_string_literal: true

require "rails/generators"

module RailsTablePreferences
  module Generators
    class JavascriptGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../../..", __dir__)

      desc "Copies the Rails Table Preferences Stimulus controller into the host application."

      def copy_stimulus_controller
        copy_file(
          "app/javascript/controllers/rails_table_preferences_controller.js",
          "app/javascript/controllers/rails_table_preferences_controller.js"
        )
      end
    end
  end
end
