# frozen_string_literal: true

require "rubygems/package"

module RailsTablePreferences
  class PackageVerifier
    REQUIRED_PATHS = [
      "app/assets/stylesheets/rails_table_preferences.css",
      "app/controllers/rails_table_preferences/application_controller.rb",
      "app/controllers/rails_table_preferences/preferences_controller.rb",
      "app/controllers/concerns/rails_table_preferences/controller.rb",
      "app/helpers/rails_table_preferences/table_preferences_helper.rb",
      "app/helpers/rails_table_preferences/column_options_helper.rb",
      "app/javascript/controllers/rails_table_preferences_controller.js",
      "app/javascript/rails_table_preferences/controller.js",
      "app/javascript/rails_table_preferences/index.js",
      "app/views/rails_table_preferences/_editor.html.erb",
      "config/routes.rb",
      "lib/generators/rails_table_preferences/install/install_generator.rb",
      "lib/generators/rails_table_preferences/install/templates/create_table_preferences.rb",
      "lib/generators/rails_table_preferences/install/templates/initializer.rb",
      "lib/generators/rails_table_preferences/install/templates/demo/orders_controller.rb",
      "lib/generators/rails_table_preferences/install/templates/demo/index.html.erb",
      "lib/generators/rails_table_preferences/javascript/javascript_generator.rb",
      "lib/generators/rails_table_preferences/stylesheets/stylesheets_generator.rb",
      "lib/generators/rails_table_preferences/views/views_generator.rb",
      "lib/tasks/rails_table_preferences.rake",
      "lib/rails_table_preferences.rb",
      "lib/rails_table_preferences/export_payload.rb",
      "lib/rails_table_preferences/package_verifier.rb",
      "lib/rails_table_preferences/settings_normalizer.rb",
      "package.json",
      "README.md",
      "CHANGELOG.md",
      "LICENSE",
      "docs/index.md",
      "docs/visual_overview.md",
      "docs/images/visual-overview-editor-and-table.svg",
      "docs/quick_start.md",
      "docs/demo.md",
      "docs/export_integration.md",
      "docs/accessibility.md",
      "docs/troubleshooting.md",
      "docs/release_checklist.md",
      "docs/package_verification.md"
    ].freeze

    attr_reader :gem_path, :required_paths

    def self.call(gem_path:, required_paths: REQUIRED_PATHS)
      new(gem_path: gem_path, required_paths: required_paths).call
    end

    def initialize(gem_path:, required_paths: REQUIRED_PATHS)
      @gem_path = gem_path.to_s
      @required_paths = Array(required_paths).map(&:to_s)
    end

    def call
      missing = required_paths - packaged_files

      {
        gem_path: gem_path,
        packaged_files: packaged_files,
        missing: missing,
        ok: missing.empty?
      }
    end

    private

    def packaged_files
      @packaged_files ||= Gem::Package.new(gem_path).spec.files.sort
    end
  end
end
