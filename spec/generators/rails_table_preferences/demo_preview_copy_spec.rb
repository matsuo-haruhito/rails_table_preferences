# frozen_string_literal: true

require "generators/rails_table_preferences/install/install_generator"

RSpec.describe "generated demo preview copy affordance", type: :generator do
  include FileUtils

  before do
    prepare_destination
  end

  it "adds demo-only copy controls for hidden fields and export evidence" do
    run_generator %w[--with-demo]

    view = file("app/views/rails_table_preferences_demo/orders/index.html.erb").read

    expect(view).to include("railsTablePreferencesDemoCopyInstalled")
    expect(view).to include("hidden fields プレビューをコピー")
    expect(view).to include("export payload プレビューをコピー")
    expect(view).to include("data-rails-table-preferences-demo-copy-trigger")
    expect(view).to include("data-rails-table-preferences-demo-copy-status")
    expect(view).to include("navigator.clipboard.writeText")
    expect(view).to include("このブラウザではコピーできません。プレビュー本文を選択してください。")
    expect(view).to include("コピーに失敗しました。プレビュー本文を選択してください。")
    expect(view).to include("通常 headers")
    expect(view).to include("include_hidden export keys")
    expect(view).not_to include("railsTablePreferencesDemoPreviewCopyInstalled")
    expect(view).not_to include("demoPreviewCopySections")
  end

  def destination_root
    File.expand_path("../../tmp/generators/demo_preview_copy", __dir__)
  end

  def prepare_destination
    rm_rf(destination_root)
    mkdir_p(destination_root)
  end

  def run_generator(args = [])
    with_captured_stdout do
      RailsTablePreferences::Generators::InstallGenerator.start(args, destination_root: destination_root)
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
end
