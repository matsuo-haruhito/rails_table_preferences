# frozen_string_literal: true

require "generators/rails_table_preferences/install/install_generator"
require "generators/rails_table_preferences/javascript/javascript_generator"
require "generators/rails_table_preferences/stylesheets/stylesheets_generator"

RSpec.describe RailsTablePreferences::Generators::InstallGenerator, type: :generator do
  include FileUtils

  before do
    prepare_destination
  end

  it "copies initializer, migration, JavaScript, and stylesheet by default" do
    run_generator

    expect(file("config/initializers/rails_table_preferences.rb")).to exist
    expect(generated_migration).to exist
    expect(file("app/javascript/controllers/rails_table_preferences_controller.js")).to exist
    expect(file("app/assets/stylesheets/rails_table_preferences.css")).to exist
    expect(file("app/controllers/rails_table_preferences_demo/orders_controller.rb")).not_to exist
    expect(file("app/views/rails_table_preferences_demo/orders/index.html.erb")).not_to exist
  end

  it "uses scoped preference columns in the generated migration" do
    run_generator

    migration = generated_migration.read

    expect(migration).to include("t.references :user, null: true")
    expect(migration).to include("t.string :scope_type")
    expect(migration).to include("t.string :scope_key")
    expect(migration).to include("[:scope_type, :scope_key, :user_id, :table_key, :name]")
    expect(migration).to include("idx_table_preferences_scope_table_name")
  end

  it "uses the configured owner model in the generated migration and initializer" do
    run_generator %w[--owner-model customers]

    migration = generated_migration.read
    initializer = file("config/initializers/rails_table_preferences.rb").read

    expect(migration).to include("t.references :customer, null: true")
    expect(migration).to include("[:scope_type, :scope_key, :customer_id, :table_key, :name]")
    expect(initializer).to include("config.owner_model = :customers")
  end

  it "uses the configured owner foreign key" do
    run_generator %w[--owner-model customers --owner-foreign-key member_id]

    migration = generated_migration.read

    expect(migration).to include("t.references :member, null: true, foreign_key: { to_table: :customers }")
    expect(migration).to include("[:scope_type, :scope_key, :member_id, :table_key, :name]")
  end

  it "can skip JavaScript copying" do
    run_generator %w[--skip-javascript]

    expect(file("config/initializers/rails_table_preferences.rb")).to exist
    expect(generated_migration).to exist
    expect(file("app/javascript/controllers/rails_table_preferences_controller.js")).not_to exist
    expect(file("app/assets/stylesheets/rails_table_preferences.css")).to exist
  end

  it "can skip stylesheet copying" do
    run_generator %w[--skip-stylesheets]

    expect(file("config/initializers/rails_table_preferences.rb")).to exist
    expect(generated_migration).to exist
    expect(file("app/javascript/controllers/rails_table_preferences_controller.js")).to exist
    expect(file("app/assets/stylesheets/rails_table_preferences.css")).not_to exist
  end

  it "can copy optional demo files" do
    run_generator %w[--with-demo]

    controller = file("app/controllers/rails_table_preferences_demo/orders_controller.rb")
    view = file("app/views/rails_table_preferences_demo/orders/index.html.erb")

    expect(controller).to exist
    expect(view).to exist
    expect(controller.read).to include("module RailsTablePreferencesDemo")
    expect(controller.read).to include("rails_table_preferences_demo_orders")
    expect(controller.read).to include("ensure_demo_shared_preset!")
    expect(controller.read).to include("ensure_demo_role_preset!")
    expect(controller.read).to include("ensure_demo_organization_preset!")
    expect(controller.read).to include("SHARED_PRESET_NAME = \"共有ビュー\"")
    expect(controller.read).to include("ROLE_PRESET_NAME = \"担当ビュー\"")
    expect(controller.read).to include("ORGANIZATION_PRESET_NAME = \"東京組織ビュー\"")
    expect(controller.read).to include("DEMO_ROLE_KEY = \"operations\"")
    expect(controller.read).to include("DEMO_ORGANIZATION_KEY = \"tokyo-hq\"")
    expect(controller.read).to include("pinned: true")
    expect(controller.read).to include("table_preferences_state(")
    expect(controller.read).to include("demo_visible_column_groups(")
    expect(controller.read).to include("受注情報")
    expect(controller.read).to include("得意先情報")
    expect(controller.read).to include("配送情報")
    expect(controller.read).to include("table_preferences_column(\n          :confirmed")
    expect(controller.read).to include("label: \"確認済\"")
    expect(controller.read).to include("filter: { type: :boolean, param: :confirmed }")
    expect(controller.read).to include("confirmed: true")
    expect(controller.read).to include("confirmed: false")
    expect(controller.read).to include("filter_by_confirmed(filtered, confirmed)")
    expect(controller.read).to include("table_preferences_column(\n          :amount")
    expect(controller.read).to include("label: \"金額\"")
    expect(controller.read).to include("filter: { type: :number, param: :amount }")
    expect(controller.read).to include("from_amount = parse_amount")
    expect(controller.read).to include("filtered = filtered.select { |order| order[:amount].to_f >= from_amount }")
    expect(controller.read).to include("filtered = filtered.select { |order| order[:amount].to_f <= to_amount }")
    expect(controller.read).to include("def parse_amount(value)")
    expect(controller.read).to include("東京医療機器")
    expect(controller.read).to include("東京製菓")
    expect(controller.read).to include("TOKYO-AM-PRIMARY-001")
    expect(controller.read).to include("ExportPayload.call")
    expect(view.read).to include("Rails Table Preferences Demo")
    expect(view.read).to include("table_preferences_editor")
    expect(view.read).to include("共有ビュー")
    expect(view.read).to include("担当ビュー")
    expect(view.read).to include("東京組織ビュー")
    expect(view.read).to include("operations")
    expect(view.read).to include("tokyo-hq")
    expect(view.read).to include("Search for")
    expect(view.read).to include("東京")
    expect(view.read).to include("demo_hidden_fields_html = table_preferences_hidden_fields")
    expect(view.read).to include("Search form hidden fields preview")
    expect(view.read).to include("demo_hidden_fields_preview = demo_hidden_fields_html.present?")
    expect(view.read).to include("h(demo_hidden_fields_preview)")
    expect(view.read).to include("Array params keep their")
    expect(view.read).to include("Export payload preview")
    expect(view.read).to include("Default column keys")
    expect(view.read).to include("Include-hidden column keys")
    expect(view.read).to include("include_hidden: true")
    expect(view.read).to include("Demo state reset")
    expect(view.read).to include("Reset demo verification state")
    expect(view.read).to include("railsTablePreferencesDemoResetInstalled")
    expect(view.read).to include("preference.editable && (preference.scope_type || \"owner\") === \"owner\"")
    expect(view.read).to include("Async failure check")
    expect(view.read).to include("Fail next preset request once")
    expect(view.read).to include("railsTablePreferencesDemoFailureInstalled")
    expect(view.read).to include("new Response(JSON.stringify({ error: \"Demo failure\" })")
    expect(view.read).to include("respond_to?(:content_security_policy_nonce)")
    expect(view.read).to include("tag.attributes(nonce: content_security_policy_nonce)")
    expect(view.read).to include("<style<%=")
    expect(view.read).to include("<script<%=")
    expect(view.read).to include("rails-table-preferences-demo-scroll")
    expect(view.read).to include("rails-table-preferences-demo-table__group-row")
    expect(view.read).to include("@demo_visible_column_groups.any?")
    expect(view.read).to include("@demo_visible_columns.each")
    expect(view.read).to include("受注情報")
    expect(view.read).to include("得意先情報")
    expect(view.read).to include("配送情報")
  end

  it "does not add the demo route when only demo files are requested" do
    prepare_routes_file

    run_generator %w[--with-demo]

    expect(file("config/routes.rb").read).not_to include(demo_route)
  end

  it "can add the optional demo route without duplicating it" do
    prepare_routes_file

    run_generator %w[--with-demo-route]
    run_generator %w[--with-demo-route]

    expect(file("app/controllers/rails_table_preferences_demo/orders_controller.rb")).to exist
    expect(file("app/views/rails_table_preferences_demo/orders/index.html.erb")).to exist
    expect(file("config/routes.rb").read.scan(demo_route).size).to eq(1)
  end

  it "does not duplicate an existing demo route written with representative syntax differences" do
    prepare_routes_file(<<~ROUTES)
      Rails.application.routes.draw do
        get(
          '/rails_table_preferences_demo/orders',
          to: 'rails_table_preferences_demo/orders#index'
        )
      end
    ROUTES

    run_generator %w[--with-demo-route]

    routes = file("config/routes.rb").read
    expect(routes).to include("'/rails_table_preferences_demo/orders'")
    expect(routes).not_to include(demo_route)
  end

  it "describes the demo route as configured when it was already present" do
    prepare_routes_file("Rails.application.routes.draw do\n  #{demo_route}\nend\n")

    output = run_generator %w[--with-demo-route]

    expect(next_step_headings(output)).to include("Demo route configured in config/routes.rb:")
    expect(output).not_to include("Demo route added to config/routes.rb:")
    expect(file("config/routes.rb").read.scan(demo_route).size).to eq(1)
  end

  it "prints the default post-install next steps with contiguous numbering" do
    output = run_generator

    expect(output).to include("Rails Table Preferences installed.", "Next steps:")
    expect(next_step_headings(output)).to eq([
      "Run: bin/rails db:migrate",
      "Mount the engine in config/routes.rb, or rerun with --with-engine-route:",
      "Ensure app/assets/stylesheets/rails_table_preferences.css is loaded by your application stylesheet.",
      "Ensure the copied Stimulus controller is registered."
    ])
    expect(output).to include("rails_table_preferences.css", "Stimulus controller", "docs/javascript_entrypoints.md")
  end

  it "keeps post-install next step numbering contiguous when optional steps are skipped" do
    output = run_generator %w[--skip-stylesheets --skip-javascript]

    expect(next_step_headings(output)).to eq([
      "Run: bin/rails db:migrate",
      "Mount the engine in config/routes.rb, or rerun with --with-engine-route:",
      "Register either a host-owned controller or the package entrypoint with the rails-table-preferences Stimulus name."
    ])
    expect(output).to include("rails_table_preferences/controller")
    expect(output).not_to include("  4.")
  end

  it "continues post-install next step numbering through demo route guidance" do
    prepare_routes_file

    output = run_generator %w[--skip-stylesheets --skip-javascript --with-demo-route]

    expect(next_step_headings(output)).to eq([
      "Run: bin/rails db:migrate",
      "Mount the engine in config/routes.rb, or rerun with --with-engine-route:",
      "Register either a host-owned controller or the package entrypoint with the rails-table-preferences Stimulus name.",
      "Demo route configured in config/routes.rb:"
    ])
    expect(output).to include("rails_table_preferences_demo/orders#index")
  end

  def destination_root
    File.expand_path("../../tmp/generators/install", __dir__)
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

  def generated_migration
    Pathname.new(Dir[File.join(destination_root, "db/migrate/*_create_table_preferences.rb")].first.to_s)
  end

  def demo_route
    'get "/rails_table_preferences_demo/orders", to: "rails_table_preferences_demo/orders#index"'
  end
end