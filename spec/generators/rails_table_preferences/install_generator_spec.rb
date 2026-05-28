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
    expect(view.read).to include("Export payload preview")
    expect(view.read).to include("Column keys")
    expect(view.read).to include("rails-table-preferences-demo-scroll")
    expect(view.read).to include("rails-table-preferences-demo-table__group-row")
    expect(view.read).to include("@demo_visible_column_groups.any?")
    expect(view.read).to include("@demo_visible_columns.each")
    expect(view.read).to include("受注情報")
    expect(view.read).to include("得意先情報")
    expect(view.read).to include("配送情報")
  end

  it "provides post-install next steps in the generator source" do
    source = File.read(File.expand_path("../../../lib/generators/rails_table_preferences/install/install_generator.rb", __dir__))

    expect(source).to include("Rails Table Preferences installed.")
    expect(source).to include("bin/rails db:migrate")
    expect(source).to include("mount RailsTablePreferences::Engine")
    expect(source).to include("rails_table_preferences.css")
    expect(source).to include("Stimulus controller")
    expect(source).to include("rails_table_preferences/controller")
    expect(source).to include("with_demo")
    expect(source).to include("rails_table_preferences_demo/orders#index")
  end

  def destination_root
    File.expand_path("../../tmp/generators/install", __dir__)
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

  def generated_migration
    Pathname.new(Dir[File.join(destination_root, "db/migrate/*_create_table_preferences.rb")].first.to_s)
  end
end
