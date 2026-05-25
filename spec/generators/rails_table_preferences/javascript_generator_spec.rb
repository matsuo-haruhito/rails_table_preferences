# frozen_string_literal: true

require "generators/rails_table_preferences/javascript/javascript_generator"

RSpec.describe RailsTablePreferences::Generators::JavascriptGenerator, type: :generator do
  include FileUtils

  before do
    prepare_destination
  end

  it "copies the Stimulus controller into the host application" do
    run_generator

    controller_path = file("app/javascript/controllers/rails_table_preferences_controller.js")
    expect(controller_path).to exist
    expect(controller_path.read).to include("export default class extends Controller")
    expect(controller_path.read).to include("static targets = [\"editorRows\", \"presetName\", \"presetSelect\", \"defaultPreset\", \"status\"]")
    expect(controller_path.read).to include('loadingStatusLabel: { type: String, default: "設定を読み込み中です..." }')
  end

  def destination_root
    File.expand_path("../../tmp/generators/javascript", __dir__)
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
