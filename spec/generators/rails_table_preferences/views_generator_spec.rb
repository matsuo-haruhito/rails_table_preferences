# frozen_string_literal: true

require "generators/rails_table_preferences/views/views_generator"
require "rails/generators/test_case"

RSpec.describe RailsTablePreferences::Generators::ViewsGenerator, type: :generator do
  include Rails::Generators::Testing::Behavior

  tests described_class
  destination File.expand_path("../../tmp/generators/views", __dir__)

  before do
    prepare_destination
  end

  it "copies the editor partial into the host application" do
    run_generator

    partial_path = file("app/views/rails_table_preferences/_editor.html.erb")
    expect(partial_path).to exist
    expect(partial_path.read).to include("rails-table-preferences-editor")
    expect(partial_path.read).to include("data-rails-table-preferences-target=\"editorRows\"")
    expect(partial_path.read).to include("data-rails-table-preferences-order-label-value=\"表示順\"")
    expect(partial_path.read).to include("保存済み設定")
    expect(partial_path.read).to include("別名で保存")
  end
end
