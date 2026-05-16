# frozen_string_literal: true

require "active_support/inflector"
require "rails/generators"
require "rails/generators/active_record"

module RailsTablePreferences
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      class_option :owner_model,
                   type: :string,
                   default: "users",
                   desc: "Model that owns table preferences. String or symbol-like, singular or plural, e.g. users, customers, client."

      class_option :owner_foreign_key,
                   type: :string,
                   default: nil,
                   desc: "Foreign key column for the owner model. Defaults to the owner model foreign key."

      class_option :skip_javascript,
                   type: :boolean,
                   default: false,
                   desc: "Skip copying the Stimulus controller into app/javascript/controllers."

      desc "Copies Rails Table Preferences migrations, initializer, and JavaScript into the host application."

      def copy_initializer
        template "initializer.rb", "config/initializers/rails_table_preferences.rb"
      end

      def copy_migration
        migration_template "create_table_preferences.rb", "db/migrate/create_table_preferences.rb"
      end

      def copy_javascript
        return if options[:skip_javascript]

        invoke "rails_table_preferences:javascript"
      end

      def owner_class_name
        owner_model.classify
      end

      def owner_foreign_key
        options[:owner_foreign_key].presence || owner_class_name.foreign_key
      end

      def owner_table_name
        owner_class_name.tableize
      end

      def owner_model
        options[:owner_model].to_s
      end

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end
    end
  end
end
