# frozen_string_literal: true

require "rails/generators"

module RailsTablePreferences
  module Generators
    class StylesheetsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../..", __dir__)

      desc "Copies the Rails Table Preferences default stylesheet into the host application."

      def copy_stylesheet
        copy_file(
          "app/assets/stylesheets/rails_table_preferences.css",
          "app/assets/stylesheets/rails_table_preferences.css"
        )
      end
    end
  end
end
