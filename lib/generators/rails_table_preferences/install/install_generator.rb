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

      class_option :skip_stylesheets,
                   type: :boolean,
                   default: false,
                   desc: "Skip copying the default stylesheet into app/assets/stylesheets."

      class_option :with_demo,
                   type: :boolean,
                   default: false,
                   desc: "Copy a lightweight demo controller and view for local browser verification."

      desc "Copies Rails Table Preferences migrations, initializer, JavaScript, and stylesheets into the host application."

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

      def copy_stylesheets
        return if options[:skip_stylesheets]

        invoke "rails_table_preferences:stylesheets"
      end

      def copy_demo
        return unless options[:with_demo]

        copy_file "demo/orders_controller.rb", "app/controllers/rails_table_preferences_demo/orders_controller.rb"
        copy_file "demo/index.html.erb", "app/views/rails_table_preferences_demo/orders/index.html.erb"
      end

      def show_post_install_message
        say "\nRails Table Preferences installed.", :green
        say "\nNext steps:"
        say "  1. Run: bin/rails db:migrate"
        say "  2. Mount the engine in config/routes.rb:"
        say "       mount RailsTablePreferences::Engine, at: \"/rails_table_preferences\""

        unless options[:skip_stylesheets]
          say "  3. Ensure app/assets/stylesheets/rails_table_preferences.css is loaded by your application stylesheet."
          say "     For Sprockets, add this if needed:"
          say "       *= require rails_table_preferences"
          say "     For Sass/CSS bundling, import the copied file from your application stylesheet."
        end

        unless options[:skip_javascript]
          say "  4. Ensure the Stimulus controller is registered."
          say "     stimulus-rails default manifests usually register app/javascript/controllers/*_controller.js automatically."
          say "     For Vite/app/frontend entrypoints, import rails_table_preferences/controller and register it manually."
        end

        if options[:with_demo]
          say "  5. Add this route if you want to open the copied demo screen:"
          say "       get \"/rails_table_preferences_demo/orders\", to: \"rails_table_preferences_demo/orders#index\""
          say "     The demo uses the configured current-user method and the table_preferences table."
          say "     Remove the copied demo controller/view before production release if they are not needed."
        end

        say ""
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
