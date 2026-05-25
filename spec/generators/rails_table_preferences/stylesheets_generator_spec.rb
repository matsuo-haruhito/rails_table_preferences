# frozen_string_literal: true

require "generators/rails_table_preferences/stylesheets/stylesheets_generator"
require "rails/generators/test_case"

RSpec.describe RailsTablePreferences::Generators::StylesheetsGenerator, type: :generator do
  include Rails::Generators::Testing::Behavior

  tests described_class
  destination File.expand_path("../../tmp/generators/stylesheets", __dir__)

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
end
