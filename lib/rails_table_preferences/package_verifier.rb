# frozen_string_literal: true

require "json"
require "pathname"
require "rubygems/package"
require "zlib"

module RailsTablePreferences
  class PackageVerifier
    REQUIRED_PATHS = [
      "app/assets/stylesheets/rails_table_preferences.css",
      "app/controllers/rails_table_preferences/application_controller.rb",
      "app/controllers/rails_table_preferences/preferences_controller.rb",
      "app/controllers/concerns/rails_table_preferences/controller.rb",
      "app/helpers/rails_table_preferences/table_preferences_helper.rb",
      "app/helpers/rails_table_preferences/table_preferences_editor_html_options_helper.rb",
      "app/helpers/rails_table_preferences/column_options_helper.rb",
      "app/javascript/controllers/rails_table_preferences_controller.js",
      "app/javascript/rails_table_preferences/controller.js",
      "app/javascript/rails_table_preferences/controller.d.ts",
      "app/javascript/rails_table_preferences/index.js",
      "app/javascript/rails_table_preferences/index.d.ts",
      "app/views/rails_table_preferences/_editor.html.erb",
      "app/views/rails_table_preferences/_resource_table.html.erb",
      "app/views/rails_table_preferences/_tree_resource_table.html.erb",
      "app/views/rails_table_preferences/_tree_resource_table_row.html.erb",
      "config/routes.rb",
      "config/locales/ja.yml",
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
      "lib/rails_table_preferences/adapters/active_record_columns.rb",
      "lib/rails_table_preferences/adapters/column_like.rb",
      "lib/rails_table_preferences/adapters/controller_params.rb",
      "lib/rails_table_preferences/adapters/ransack.rb",
      "lib/rails_table_preferences/column_definition.rb",
      "lib/rails_table_preferences/configuration.rb",
      "lib/rails_table_preferences/export_payload.rb",
      "lib/rails_table_preferences/package_verifier.rb",
      "lib/rails_table_preferences/renderer_registry.rb",
      "lib/rails_table_preferences/settings_normalizer.rb",
      "lib/rails_table_preferences/table_profile.rb",
      "lib/rails_table_preferences/table_state.rb",
      "lib/rails_table_preferences/value_resolver.rb",
      "package.json",
      "README.md",
      "CHANGELOG.md",
      "LICENSE",
      "docs/index.md",
      "docs/quick_start.md",
      "docs/quick_start_ja.md",
      "docs/install_paths.md",
      "docs/resource_tables.md",
      "docs/resource_table_cell_hooks.md",
      "docs/table_data_attributes.md",
      "docs/resource_table_formatter_contract.md",
      "docs/virtual_columns_query_boundary.md",
      "docs/decision_guide.md",
      "docs/scoped_presets.md",
      "docs/preset_selector_scope_labels.md",
      "docs/fixed_columns_and_groups.md",
      "docs/column_overflow.md",
      "docs/resize_auto_fit.md",
      "docs/export_integration.md",
      "docs/accessibility.md",
      "docs/editor_i18n.md",
      "docs/editor_entrypoint_affordances.md",
      "docs/editor_root_options.md",
      "docs/helper_free_controller_root_urls.md",
      "docs/non_goals.md",
      "docs/visual_overview.md",
      "docs/images/visual-overview-editor-and-table.svg",
      "docs/images/visual-overview-filter-and-pinned-columns.svg",
      "docs/demo.md",
      "docs/sandbox.md",
      "docs/examples.md",
      "docs/troubleshooting.md",
      "docs/manual_qa.md",
      "docs/release_checklist.md",
      "docs/package_verification.md",
      "docs/support_matrix.md",
      "docs/controller_integration.md",
      "docs/json_api.md",
      "docs/filter_metadata.md",
      "docs/filter_adapters.md",
      "docs/select_filter_troubleshooting.md",
      "docs/javascript_entrypoints.md",
      "docs/javascript_controller.md"
    ].freeze

    SUMMARY_CATEGORIES = [
      [:missing, "required files"],
      [:missing_package_export_targets, "package export targets"],
      [:missing_package_internal_imports, "package internal JavaScript imports"],
      [:missing_package_declaration_imports, "package internal declaration imports"],
      [:package_json_errors, "package metadata errors"]
    ].freeze

    RELATIVE_IMPORT_PATTERN = /(?:^|\n)\s*(?:import\s+(?:[^"'\n]+?\s+from\s+)?|export\s+[^"'\n]+?\s+from\s+)["'](?<specifier>\.[^"']+)["']/.freeze

    attr_reader :gem_path, :required_paths

    def self.call(gem_path:, required_paths: REQUIRED_PATHS)
      new(gem_path: gem_path, required_paths: required_paths).call
    end

    def self.summary(result)
      counts = SUMMARY_CATEGORIES.to_h do |key, _label|
        [key, Array(result.fetch(key, [])).size]
      end

      {
        ok: result.fetch(:ok, false),
        total: counts.values.sum,
        counts: counts
      }
    end

    def self.summary_lines(result)
      summary = summary(result)
      return ["Package verification summary: ok"] if summary.fetch(:ok)

      counts = summary.fetch(:counts)
      details = SUMMARY_CATEGORIES.map do |key, label|
        "#{label}: #{counts.fetch(key)}"
      end.join(", ")

      ["Package verification summary: #{summary.fetch(:total)} issue(s) (#{details})"]
    end

    def initialize(gem_path:, required_paths: REQUIRED_PATHS)
      @gem_path = gem_path.to_s
      @required_paths = Array(required_paths).map(&:to_s)
    end

    def call
      missing = required_paths - packaged_files
      missing_package_export_targets = package_export_targets.reject do |export_target|
        packaged_files.include?(export_target.fetch(:target))
      end
      missing_package_internal_imports = self.missing_package_internal_imports
      missing_package_declaration_imports = self.missing_package_declaration_imports
      package_json_errors = self.package_json_errors

      {
        gem_path: gem_path,
        packaged_files: packaged_files,
        missing: missing,
        missing_package_export_targets: missing_package_export_targets,
        missing_package_internal_imports: missing_package_internal_imports,
        missing_package_declaration_imports: missing_package_declaration_imports,
        package_json_errors: package_json_errors,
        ok: missing.empty? &&
          missing_package_export_targets.empty? &&
          missing_package_internal_imports.empty? &&
          missing_package_declaration_imports.empty? &&
          package_json_errors.empty?
      }
    end

    private

    def packaged_files
      @packaged_files ||= Gem::Package.new(gem_path).spec.files.sort
    end

    def package_export_targets
      @package_export_targets ||= begin
        return [] unless packaged_files.include?("package.json")

        exports = package_json.fetch("exports", {})
        export_targets_for(exports).sort_by { |target| [target.fetch(:export), target.fetch(:target)] }
      end
    end

    def missing_package_internal_imports
      @missing_package_internal_imports ||= missing_package_relative_imports(extension: ".js")
    end

    def missing_package_declaration_imports
      @missing_package_declaration_imports ||= missing_package_relative_imports(extension: ".d.ts")
    end

    def missing_package_relative_imports(extension:)
      package_export_targets.flat_map do |export_target|
        entrypoint = export_target.fetch(:target)
        next [] unless entrypoint.end_with?(extension) && packaged_files.include?(entrypoint)

        relative_imports_for(entrypoint).filter_map do |specifier|
          resolved_target = resolve_relative_import(entrypoint, specifier, extension: extension)
          next if resolved_target

          {
            export: export_target.fetch(:export),
            entrypoint: entrypoint,
            import: specifier,
            target: unresolved_relative_import_target(entrypoint, specifier)
          }
        end
      end.sort_by { |missing_import| [missing_import.fetch(:entrypoint), missing_import.fetch(:import)] }
    end

    def relative_imports_for(entrypoint)
      packaged_file_contents(entrypoint).scan(RELATIVE_IMPORT_PATTERN).flatten.uniq.sort
    end

    def resolve_relative_import(entrypoint, specifier, extension:)
      candidate = unresolved_relative_import_target(entrypoint, specifier)
      candidates = [candidate]
      if File.extname(candidate).empty?
        candidates << "#{candidate}#{extension}"
        candidates << File.join(candidate, "index#{extension}")
      end

      candidates.find { |path| packaged_files.include?(path) }
    end

    def unresolved_relative_import_target(entrypoint, specifier)
      Pathname.new(File.dirname(entrypoint)).join(specifier).cleanpath.to_s
    end

    def package_json
      @package_json ||= JSON.parse(packaged_file_contents("package.json"))
    rescue JSON::ParserError => e
      @package_json_parse_error = "package.json could not be parsed: #{e.message}"
      {}
    end

    def package_json_errors
      @package_json_errors ||= begin
        if packaged_files.include?("package.json")
          metadata = package_json
          errors = []
          errors << @package_json_parse_error if @package_json_parse_error
          errors.concat(package_metadata_errors(metadata)) unless @package_json_parse_error
          errors
        else
          []
        end
      end
    end

    def package_metadata_errors(metadata)
      errors = []
      unless metadata["private"] == true
        errors << "package.json private must remain true because the file is gem-packaged resolver metadata, not npm distribution policy"
      end
      unless metadata["version"] == "0.0.0"
        errors << "package.json version must remain 0.0.0 because JavaScript package versioning is not a Ruby gem release policy"
      end
      errors
    end

    def export_targets_for(value, export_name = ".")
      case value
      when String
        [{ export: export_name, target: normalize_package_target(value) }]
      when Hash
        value.flat_map do |key, nested_value|
          export_targets_for(nested_value, key.to_s.start_with?(".") ? key.to_s : export_name)
        end
      else
        package_json_errors << "package.json exports entry #{export_name.inspect} must point to a string or object"
        []
      end
    end

    def normalize_package_target(target)
      target.to_s.sub(%r{\A\./}, "")
    end

    def packaged_file_contents(path)
      File.open(gem_path, "rb") do |file|
        Gem::Package::TarReader.new(file) do |gem_tar|
          gem_tar.each do |entry|
            next unless entry.full_name == "data.tar.gz"

            return contents_from_data_tar(entry, path)
          end
        end
      end

      raise KeyError, "#{path} was not found in #{gem_path}"
    end

    def contents_from_data_tar(entry, path)
      Zlib::GzipReader.wrap(entry) do |gzip|
        Gem::Package::TarReader.new(gzip) do |data_tar|
          data_tar.each do |data_entry|
            return data_entry.read if data_entry.full_name == path
          end
        end
      end

      raise KeyError, "#{path} was not found in #{gem_path}"
    end
  end
end
