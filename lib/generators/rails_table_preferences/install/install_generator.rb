# frozen_string_literal: true

require "active_support/inflector"
require "rails/generators"
require "rails/generators/active_record"

module RailsTablePreferences
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)
      DEMO_ROUTE = 'get "/rails_table_preferences_demo/orders", to: "rails_table_preferences_demo/orders#index"'

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
                   desc: "Skip copying the Stimulus controller. Use with the package entrypoint or a host-owned controller."

      class_option :skip_stylesheets,
                   type: :boolean,
                   default: false,
                   desc: "Skip copying the default stylesheet into app/assets/stylesheets."

      class_option :with_demo,
                   type: :boolean,
                   default: false,
                   desc: "Copy a lightweight demo controller and view for local browser verification."

      class_option :with_demo_route,
                   type: :boolean,
                   default: false,
                   desc: "Also add the demo route to config/routes.rb. Implies --with-demo."

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
        return unless demo_requested?

        copy_file "demo/orders_controller.rb", "app/controllers/rails_table_preferences_demo/orders_controller.rb"
        copy_file "demo/index.html.erb", "app/views/rails_table_preferences_demo/orders/index.html.erb"
      end

      def add_demo_route
        return unless options[:with_demo_route]

        routes_path = File.join(destination_root, "config/routes.rb")
        if File.exist?(routes_path) && File.read(routes_path).include?(DEMO_ROUTE)
          say_status :identical, "config/routes.rb"
        else
          route DEMO_ROUTE
        end
      end

      def show_post_install_message
        say "\nRails Table Preferences installed.", :green
        say "\nNext steps:"

        post_install_steps.each.with_index(1) do |lines, index|
          say "  #{index}. #{lines.first}"
          lines.drop(1).each { |line| say line }
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

      private

      def post_install_steps
        steps = [
          ["Run: bin/rails db:migrate"],
          [
            "Mount the engine in config/routes.rb:",
            "       mount RailsTablePreferences::Engine, at: \"/rails_table_preferences\""
          ]
        ]

        unless options[:skip_stylesheets]
          steps << [
            "Ensure app/assets/stylesheets/rails_table_preferences.css is loaded by your application stylesheet.",
            "     For Sprockets, add this if needed:",
            "       *= require rails_table_preferences",
            "     For Sass/CSS bundling, import the copied file from your application stylesheet."
          ]
        end

        steps << if options[:skip_javascript]
                   [
                     "Register either a host-owned controller or the package entrypoint with the rails-table-preferences Stimulus name.",
                     "     Package entrypoint example: import rails_table_preferences/controller and register it from your app entrypoint.",
                     "     See docs/javascript_entrypoints.md for Vite/app/frontend resolver notes."
                   ]
                 else
                   [
                     "Ensure the copied Stimulus controller is registered.",
                     "     stimulus-rails default manifests usually register app/javascript/controllers/*_controller.js automatically.",
                     "     For Vite/app/frontend package entrypoint installs, rerun with --skip-javascript and register rails_table_preferences/controller manually.",
                     "     See docs/javascript_entrypoints.md for resolver notes."
                   ]
                 end

        if demo_requested?
          steps << [
            demo_route_step_heading,
            "       #{DEMO_ROUTE}",
            "     The demo uses the configured current-user method and the table_preferences table.",
            "     Remove the copied demo controller/view and route before production release if they are not needed."
          ]
        end

        steps
      end

      def demo_route_step_heading
        if options[:with_demo_route]
          "Demo route added to config/routes.rb:"
        else
          "Add this route if you want to open the copied demo screen, or rerun with --with-demo-route:"
        end
      end

      def demo_requested?
        options[:with_demo] || options[:with_demo_route]
      end
    end
  end
end
