# frozen_string_literal: true

require "spec_helper"
require "rails_table_preferences/package_verifier"
require "rexml/document"

RSpec.describe RailsTablePreferences::PackageVerifier do
  describe "REQUIRED_PATHS" do
    it "keeps the documented package verification list synchronized" do
      docs = File.read(repository_root.join("docs/package_verification.md"))
      required_files_section = docs.split("## Required files", 2).last
      documented_paths = required_files_section
        .match(/```text\n(?<paths>.*?)\n```/m)[:paths]
        .lines
        .map(&:strip)
        .reject(&:empty?)

      expect(documented_paths).to eq(described_class::REQUIRED_PATHS)
    end

    it "guards JavaScript entrypoints and their packaged declarations" do
      expect(described_class::REQUIRED_PATHS).to include(
        "app/javascript/rails_table_preferences/controller.js",
        "app/javascript/rails_table_preferences/controller.d.ts",
        "app/javascript/rails_table_preferences/index.js",
        "app/javascript/rails_table_preferences/index.d.ts"
      )
    end

    it "guards resource table default partials used by public helpers" do
      expect(described_class::REQUIRED_PATHS).to include(
        "app/views/rails_table_preferences/_resource_table.html.erb",
        "app/views/rails_table_preferences/_tree_resource_table.html.erb",
        "app/views/rails_table_preferences/_tree_resource_table_row.html.erb"
      )
    end

    it "guards editor helper extensions that are documented package entrypoints" do
      expect(described_class::REQUIRED_PATHS).to include(
        "app/helpers/rails_table_preferences/table_preferences_editor_html_options_helper.rb",
        "docs/editor_root_options.md"
      )
    end

    it "guards representative README-linked docs and visual assets" do
      expect(described_class::REQUIRED_PATHS).to include(
        "docs/quick_start.md",
        "docs/quick_start_ja.md",
        "docs/install_paths.md",
        "docs/resource_tables.md",
        "docs/resource_table_cell_hooks.md",
        "docs/table_data_attributes.md",
        "docs/resource_table_formatter_contract.md",
        "docs/decision_guide.md",
        "docs/scoped_presets.md",
        "docs/fixed_columns_and_groups.md",
        "docs/column_overflow.md",
        "docs/resize_auto_fit.md",
        "docs/export_integration.md",
        "docs/accessibility.md",
        "docs/editor_i18n.md",
        "docs/editor_root_options.md",
        "docs/non_goals.md",
        "docs/visual_overview.md",
        "docs/images/visual-overview-editor-and-table.svg",
        "docs/images/visual-overview-filter-and-pinned-columns.svg",
        "docs/demo.md",
        "docs/sandbox.md",
        "docs/examples.md",
        "docs/troubleshooting.md",
        "docs/manual_qa.md",
        "docs/package_verification.md",
        "docs/support_matrix.md",
        "docs/controller_integration.md",
        "docs/json_api.md",
        "docs/filter_metadata.md",
        "docs/filter_adapters.md",
        "docs/select_filter_troubleshooting.md",
        "docs/javascript_entrypoints.md",
        "docs/javascript_controller.md"
      )
    end

    it "guards visual overview SVG accessibility metadata" do
      required_overview_svg_paths.each do |path|
        document = REXML::Document.new(File.read(repository_root.join(path)))
        svg = document.root
        labelledby_ids = svg.attributes["aria-labelledby"].to_s.split
        referenced_elements = labelledby_ids.map do |id|
          REXML::XPath.first(svg, ".//*[@id='#{id}']")
        end

        expect(svg.name).to eq("svg")
        expect(svg.attributes["role"]).to eq("img")
        expect(labelledby_ids).to include("title", "desc")
        expect(referenced_elements).to all(be_present)
        expect(REXML::XPath.first(svg, "./title").text.to_s.strip).not_to be_empty
        expect(REXML::XPath.first(svg, "./desc").text.to_s.strip).not_to be_empty
      end
    end
  end

  describe "#call" do
    it "accepts packaged JavaScript entrypoints whose internal relative imports resolve" do
      result = package_verification_result(
        packaged_files: package_entrypoint_files,
        javascript_files: {
          "app/javascript/rails_table_preferences/index.js" => <<~JS,
            export { default } from "./controller"
            export { default as RailsTablePreferencesController } from "./controller"
          JS
          "app/javascript/rails_table_preferences/controller.js" => <<~JS,
            import RailsTablePreferencesBaseController from "../controllers/rails_table_preferences_controller"

            export default class RailsTablePreferencesController extends RailsTablePreferencesBaseController {}
          JS
          "app/javascript/rails_table_preferences/index.d.ts" => <<~TS,
            export { default } from "./controller"
            export { default as RailsTablePreferencesController } from "./controller"
          TS
          "app/javascript/rails_table_preferences/controller.d.ts" => <<~TS
            export default class RailsTablePreferencesController {}
          TS
        }
      )

      expect(result[:missing_package_internal_imports]).to eq([])
      expect(result[:missing_package_declaration_imports]).to eq([])
      expect(result[:ok]).to be(true)
    end

    it "reports packaged JavaScript entrypoints whose internal relative imports are missing" do
      result = package_verification_result(
        packaged_files: package_entrypoint_files - ["app/javascript/controllers/rails_table_preferences_controller.js"],
        javascript_files: {
          "app/javascript/rails_table_preferences/index.js" => "export { default } from \"./controller\"\n",
          "app/javascript/rails_table_preferences/controller.js" => <<~JS,
            import RailsTablePreferencesBaseController from "../controllers/rails_table_preferences_controller"

            export default class RailsTablePreferencesController extends RailsTablePreferencesBaseController {}
          JS
          "app/javascript/rails_table_preferences/index.d.ts" => "export { default } from \"./controller\"\n",
          "app/javascript/rails_table_preferences/controller.d.ts" => "export default class RailsTablePreferencesController {}\n"
        }
      )

      expect(result[:missing_package_internal_imports]).to contain_exactly(
        {
          export: "./controller",
          entrypoint: "app/javascript/rails_table_preferences/controller.js",
          import: "../controllers/rails_table_preferences_controller",
          target: "app/javascript/controllers/rails_table_preferences_controller"
        }
      )
      expect(result[:missing_package_declaration_imports]).to eq([])
      expect(result[:ok]).to be(false)
    end
  end

  describe ".summary" do
    it "counts each package verification failure category separately" do
      result = {
        ok: false,
        missing: ["docs/package_verification.md", "README.md"],
        missing_package_export_targets: [
          { export: ".", target: "app/javascript/rails_table_preferences/index.js" }
        ],
        missing_package_internal_imports: [
          { export: "./controller", entrypoint: "app/javascript/rails_table_preferences/controller.js", import: "../controllers/rails_table_preferences_controller", target: "app/javascript/controllers/rails_table_preferences_controller" }
        ],
        missing_package_declaration_imports: [],
        package_json_errors: ["package.json could not be parsed"]
      }

      expect(described_class.summary(result)).to eq(
        ok: false,
        total: 5,
        counts: {
          missing: 2,
          missing_package_export_targets: 1,
          missing_package_internal_imports: 1,
          missing_package_declaration_imports: 0,
          package_json_errors: 1
        }
      )
    end

    it "formats a compact failure summary for release evidence" do
      result = {
        ok: false,
        missing: ["docs/package_verification.md"],
        missing_package_export_targets: [],
        missing_package_internal_imports: [
          { export: "./controller", entrypoint: "app/javascript/rails_table_preferences/controller.js", import: "../controllers/rails_table_preferences_controller", target: "app/javascript/controllers/rails_table_preferences_controller" }
        ],
        missing_package_declaration_imports: [],
        package_json_errors: []
      }

      expect(described_class.summary_lines(result)).to eq([
        "Package verification summary: 2 issue(s) (required files: 1, package export targets: 0, package internal JavaScript imports: 1, package internal declaration imports: 0, package metadata errors: 0)"
      ])
    end

    it "formats a compact passing summary without changing the call result shape" do
      result = {
        ok: true,
        missing: [],
        missing_package_export_targets: [],
        missing_package_internal_imports: [],
        missing_package_declaration_imports: [],
        package_json_errors: []
      }

      expect(described_class.summary_lines(result)).to eq(["Package verification summary: ok"])
    end
  end

  def repository_root
    Pathname.new(File.expand_path("../..", __dir__))
  end

  def required_overview_svg_paths
    described_class::REQUIRED_PATHS.grep(%r{\Adocs/images/visual-overview-.*\.svg\z})
  end

  def package_entrypoint_files
    [
      "package.json",
      "app/javascript/controllers/rails_table_preferences_controller.js",
      "app/javascript/rails_table_preferences/controller.js",
      "app/javascript/rails_table_preferences/controller.d.ts",
      "app/javascript/rails_table_preferences/index.js",
      "app/javascript/rails_table_preferences/index.d.ts"
    ]
  end

  def package_verification_result(packaged_files:, javascript_files:)
    verifier = described_class.new(gem_path: "pkg/rails_table_preferences-test.gem", required_paths: packaged_files)

    allow(verifier).to receive(:packaged_files).and_return(packaged_files.sort)
    allow(verifier).to receive(:packaged_file_contents) do |path|
      if path == "package.json"
        JSON.generate(
          "exports" => {
            "." => {
              "types" => "./app/javascript/rails_table_preferences/index.d.ts",
              "default" => "./app/javascript/rails_table_preferences/index.js"
            },
            "./controller" => {
              "types" => "./app/javascript/rails_table_preferences/controller.d.ts",
              "default" => "./app/javascript/rails_table_preferences/controller.js"
            }
          }
        )
      else
        javascript_files.fetch(path)
      end
    end

    verifier.call
  end
end
