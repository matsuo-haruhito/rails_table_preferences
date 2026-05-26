# frozen_string_literal: true

require "bundler/setup"
require "fileutils"
require "pathname"
require "active_record"
require "action_controller/railtie"
require "rspec/rails"
require "capybara"
require "capybara/dsl"
require "selenium-webdriver"
require "rails_table_preferences"

class ApplicationController < ActionController::Base
  def current_user
    Thread.current[:rails_table_preferences_current_user]
  end

  def table_preference_scope_context
    Thread.current[:rails_table_preferences_scope_context] || {}
  end
end

class TestApplication < Rails::Application
  config.root = File.expand_path("..", __dir__)
  config.eager_load = false
  config.secret_key_base = "test-secret-key-base"
  config.hosts.clear

  routes.append do
    mount RailsTablePreferences::Engine, at: RailsTablePreferences.configuration.mount_path
  end
end

Rails.application.initialize! unless Rails.application.initialized?

Capybara.app = Rails.application
Capybara.server = :puma, { Silent: true }
Capybara.register_driver :rails_table_preferences_headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  %w[headless disable-gpu no-sandbox disable-dev-shm-usage window-size=1400,1200].each do |argument|
    options.add_argument(argument)
  end

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
Capybara.javascript_driver = :rails_table_preferences_headless_chrome

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.timestamps
  end

  create_table :table_preferences, force: true do |t|
    t.references :user, null: true
    t.string :scope_type, null: false, default: "owner"
    t.string :scope_key, null: false, default: ""
    t.string :table_key, null: false
    t.string :name, null: false, default: "default"
    t.json :settings, null: false
    t.boolean :default_flag, null: false, default: false
    t.timestamps
  end

  add_index :table_preferences, [:scope_type, :scope_key, :user_id, :table_key, :name], unique: true, name: "idx_table_preferences_scope_table_name"
end

class User < ActiveRecord::Base
end

module GeneratorSpecHelpers
  def file(path)
    Pathname.new(destination_root).join(path)
  end
end

RSpec.configure do |config|
  config.include FileUtils, type: :generator
  config.include GeneratorSpecHelpers, type: :generator
  config.include Capybara::DSL, type: :system

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.infer_spec_type_from_file_location!

  config.before(type: :system) do
    Capybara.current_driver = RSpec.current_example.metadata[:js] ? Capybara.javascript_driver : Capybara.default_driver
  end

  config.before do
    RailsTablePreferences.configuration = RailsTablePreferences::Configuration.new
    RailsTablePreferences.configuration.scope_context_method = :table_preference_scope_context
    RailsTablePreferences::Preference.table_name = RailsTablePreferences.configuration.table_name
    RailsTablePreferences::Preference.delete_all
    User.delete_all
    Thread.current[:rails_table_preferences_current_user] = nil
    Thread.current[:rails_table_preferences_scope_context] = nil
  end

  config.after do
    Thread.current[:rails_table_preferences_current_user] = nil
    Thread.current[:rails_table_preferences_scope_context] = nil
  end

  config.after(type: :system) do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
