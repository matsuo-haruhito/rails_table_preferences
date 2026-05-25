# frozen_string_literal: true

require "generators/rails_table_preferences/stylesheets/stylesheets_generator"

RSpec.describe RailsTablePreferences::Generators::StylesheetsGenerator, type: :generator do
  include FileUtils

  before do
    prepare_destination
  end

  it "copies the default stylesheet into the host application" do
    run_generator

    stylesheet_path = file("app/assets/stylesheets/rails_table_preferences.css")
    expect(stylesheet_path).to exist
    expect(stylesheet_path.read).to include(".rails-table-preferences-editor__row")
    expect(stylesheet_path.read).to include("grid-template-columns")
    expect(stylesheet_path.read).to include("text-overflow: ellipsis")
    expect(stylesheet_path.read).to include(".rails-table-preferences-filter-button")
    expect(stylesheet_path.read).to include(".rails-table-preferences-filter-panel")
  end

  def destination_root
    File.expand_path("../../tmp/generators/stylesheets", __dir__)
  end

  def prepare_destination
    rm_rf(destination_root)
    mkdir_p(destination_root)
  end

  def run_generator(args = [])
    with_captured_stdout do
      described_class.start(args, destination_root: destination_root)
    end
  end

  def with_captured_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original_stdout
  end
end
