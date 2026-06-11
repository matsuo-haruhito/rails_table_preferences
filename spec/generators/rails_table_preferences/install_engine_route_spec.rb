# frozen_string_literal: true

require "generators/rails_table_preferences/install/install_generator"
require "generators/rails_table_preferences/javascript/javascript_generator"
require "generators/rails_table_preferences/stylesheets/stylesheets_generator"

RSpec.describe RailsTablePreferences::Generators::InstallGenerator, type: :generator do
  include FileUtils

  before do
    prepare_destination
    prepare_routes_file
  end

  it "does not add the engine mount route by default" do
    run_generator

    expect(file("config/routes.rb").read).not_to include(engine_route)
  end

  it "can add the optional engine mount route without duplicating it" do
    run_generator %w[--with-engine-route]
    run_generator %w[--with-engine-route]

    expect(file("config/routes.rb").read.scan(engine_route).size).to eq(1)
  end

  it "does not duplicate an existing engine mount route written with representative syntax differences" do
    prepare_routes_file(<<~ROUTES)
      Rails.application.routes.draw do
        mount(
          RailsTablePreferences::Engine,
          at: '/rails_table_preferences'
        )
      end
    ROUTES

    run_generator %w[--with-engine-route]

    routes = file("config/routes.rb").read
    expect(routes).to include("at: '/rails_table_preferences'")
    expect(routes).not_to include(engine_route)
  end

  it "keeps engine and demo route options independent and idempotent" do
    run_generator %w[--with-engine-route --with-demo-route]
    run_generator %w[--with-engine-route --with-demo-route]

    routes = file("config/routes.rb").read
    expect(routes.scan(engine_route).size).to eq(1)
    expect(routes.scan(demo_route).size).to eq(1)
    expect(file("app/controllers/rails_table_preferences_demo/orders_controller.rb")).to exist
    expect(file("app/views/rails_table_preferences_demo/orders/index.html.erb")).to exist
  end

  it "describes the engine route as configured when the option is used" do
    output = run_generator %w[--with-engine-route]

    expect(next_step_headings(output)).to include("Engine route configured in config/routes.rb:")
    expect(next_step_headings(output)).not_to include("Mount the engine in config/routes.rb, or rerun with --with-engine-route:")
  end

  def destination_root
    File.expand_path("../../tmp/generators/install_engine_route", __dir__)
  end

  def prepare_destination
    rm_rf(destination_root)
    mkdir_p(destination_root)
  end

  def prepare_routes_file(content = nil)
    mkdir_p(File.join(destination_root, "config"))
    File.write(
      File.join(destination_root, "config/routes.rb"),
      content || "Rails.application.routes.draw do\nend\n"
    )
  end

  def run_generator(args = [])
    with_captured_stdout do
      described_class.start(args, destination_root: destination_root)
    end
  end

  def with_captured_stdout
    original_stdout = $stdout
    stdout = StringIO.new
    $stdout = stdout
    yield
    stdout.string
  ensure
    $stdout = original_stdout
  end

  def next_step_headings(output)
    output.lines.grep(/^\s+\d+\. /).map { |line| line.sub(/^\s+\d+\. /, "").strip }
  end

  def engine_route
    'mount RailsTablePreferences::Engine, at: "/rails_table_preferences"'
  end

  def demo_route
    'get "/rails_table_preferences_demo/orders", to: "rails_table_preferences_demo/orders#index"'
  end
end
