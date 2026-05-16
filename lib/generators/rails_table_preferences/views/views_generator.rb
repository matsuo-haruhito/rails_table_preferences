# frozen_string_literal: true

require "rails/generators"

module RailsTablePreferences
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Copies Rails Table Preferences view templates into the host application for customization."

      def copy_editor_partial
        template "_editor.html.erb", "app/views/rails_table_preferences/_editor.html.erb"
      end
    end
  end
end
