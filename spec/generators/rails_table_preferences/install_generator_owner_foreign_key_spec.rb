# frozen_string_literal: true

require "generators/rails_table_preferences/install/install_generator"
require "generators/rails_table_preferences/javascript/javascript_generator"
require "generators/rails_table_preferences/stylesheets/stylesheets_generator"

RSpec.describe "rails_table_preferences:install owner foreign key", type: :generator do
  include FileUtils

  before do
    prepare_destination
  end

  it "rejects owner foreign keys that do not match the generated t.references column" do
    expect do
      run_generator %w[--owner-model customers --owner-foreign-key account_uuid]
    end.to raise_error(Thor::Error, /--owner-foreign-key must end with _id/)

    expect(generated_migration).not_to exist
  end

  def destination_root
    File.expand_path("../../tmp/generators/install_owner_foreign_key", __dir__)
  end

  def prepare_destination
    rm_rf(destination_root)
    mkdir_p(destination_root)
  end

  def run_generator(args = [])
    described_class.start(args, destination_root: destination_root)
  end

  def generated_migration
    Pathname.new(Dir[File.join(destination_root, "db/migrate/*_create_table_preferences.rb")].first.to_s)
  end
end
