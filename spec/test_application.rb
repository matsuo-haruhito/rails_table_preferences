# frozen_string_literal: true

require "active_record"
require "action_controller/railtie"
require "action_view/railtie"
require "rails_table_preferences"

unless defined?(ApplicationController)
  class ApplicationController < ActionController::Base
    def current_user
      Thread.current[:rails_table_preferences_current_user]
    end

    def table_preference_scope_context
      Thread.current[:rails_table_preferences_scope_context] || {}
    end
  end
end

unless defined?(TestApplication)
  class TestApplication < Rails::Application
    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.secret_key_base = "test-secret-key-base"
    config.hosts.clear

    routes.append do
      mount RailsTablePreferences::Engine, at: RailsTablePreferences.configuration.mount_path
    end
  end
end

Rails.application.initialize! unless Rails.application.initialized?
