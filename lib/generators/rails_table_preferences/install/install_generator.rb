# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module RailsTablePreferences
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Copies Rails Table Preferences migrations into the host application."

      def copy_migration
        migration_template "create_table_preferences.rb", "db/migrate/create_table_preferences.rb"
      end

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end
    end
  end
end
