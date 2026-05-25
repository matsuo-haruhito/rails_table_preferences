# frozen_string_literal: true

require "generators/rails_table_preferences/views/views_generator"

RSpec.describe RailsTablePreferences::Generators::ViewsGenerator, type: :generator do
  include FileUtils

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

  def destination_root
    File.expand_path("../../tmp/generators/views", __dir__)
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
