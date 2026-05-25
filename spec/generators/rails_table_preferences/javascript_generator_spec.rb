# frozen_string_literal: true

require "generators/rails_table_preferences/javascript/javascript_generator"
require "rails/generators/testing/behavior"

RSpec.describe RailsTablePreferences::Generators::JavascriptGenerator, type: :generator do
  include Rails::Generators::Testing::Behavior

  tests described_class
  destination File.expand_path("../../tmp/generators/javascript", __dir__)

  before do
    prepare_destination
  end

  it "copies the Stimulus controller into the host application" do
    run_generator

    controller_path = file("app/javascript/controllers/rails_table_preferences_controller.js")
    expect(controller_path).to exist
    expect(controller_path.read).to include("export default class extends Controller")
    expect(controller_path.read).to include("static targets = [\"editorRows\", \"presetName\", \"presetSelect\", \"defaultPreset\", \"status\", \"readOnlyHint\"]")
    expect(controller_path.read).to include('readOnlyPresetHintLabel: { type: String, default: "この設定は直接上書きできません。保存すると個人用の新しい設定として保存されます。" }')
    expect(controller_path.read).to include('loadingStatusLabel: { type: String, default: "設定を読み込み中です..." }')
  end
end
