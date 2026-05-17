# frozen_string_literal: true

require "generators/rails_table_preferences/install/install_generator"
require "generators/rails_table_preferences/javascript/javascript_generator"
require "generators/rails_table_preferences/stylesheets/stylesheets_generator"
require "rails/generators/testing/behavior"

RSpec.describe RailsTablePreferences::Generators::InstallGenerator, type: :generator do
  include Rails::Generators::Testing::Behavior

  tests described_class
  destination File.expand_path("../../tmp/generators/install", __dir__)

  before do
    prepare_destination
  end

  it "copies initializer, migration, JavaScript, and stylesheet by default" do
    run_generator

    expect(file("config/initializers/rails_table_preferences.rb")).to exist
    expect(file("db/migrate/create_table_preferences.rb")).to exist
    expect(file("app/javascript/controllers/rails_table_preferences_controller.js")).to exist
    expect(file("app/assets/stylesheets/rails_table_preferences.css")).to exist
  end

  it "uses the configured owner model in the generated migration and initializer" do
    run_generator %w[--owner-model customers]

    migration = file("db/migrate/create_table_preferences.rb").read
    initializer = file("config/initializers/rails_table_preferences.rb").read

    expect(migration).to include("t.references :customer")
    expect(migration).to include("[:customer_id, :table_key, :name]")
    expect(initializer).to include("config.owner_model = :customers")
  end

  it "uses the configured owner foreign key" do
    run_generator %w[--owner-model customers --owner-foreign-key member_id]

    migration = file("db/migrate/create_table_preferences.rb").read

    expect(migration).to include("t.references :customer, null: false, foreign_key: { to_table: :customers }")
    expect(migration).to include("add_index :table_preferences, [:member_id, :table_key, :name]")
  end

  it "can skip JavaScript copying" do
    run_generator %w[--skip-javascript]

    expect(file("config/initializers/rails_table_preferences.rb")).to exist
    expect(file("db/migrate/create_table_preferences.rb")).to exist
    expect(file("app/javascript/controllers/rails_table_preferences_controller.js")).not_to exist
    expect(file("app/assets/stylesheets/rails_table_preferences.css")).to exist
  end

  it "can skip stylesheet copying" do
    run_generator %w[--skip-stylesheets]

    expect(file("config/initializers/rails_table_preferences.rb")).to exist
    expect(file("db/migrate/create_table_preferences.rb")).to exist
    expect(file("app/javascript/controllers/rails_table_preferences_controller.js")).to exist
    expect(file("app/assets/stylesheets/rails_table_preferences.css")).not_to exist
  end

  it "prints post-install next steps" do
    output = capture(:stdout) do
      run_generator
    end

    expect(output).to include("Rails Table Preferences installed.")
    expect(output).to include("bin/rails db:migrate")
    expect(output).to include("mount RailsTablePreferences::Engine")
    expect(output).to include("rails_table_preferences.css")
    expect(output).to include("Stimulus controller")
  end
end
