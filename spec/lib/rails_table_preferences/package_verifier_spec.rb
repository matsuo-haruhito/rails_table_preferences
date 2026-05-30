# frozen_string_literal: true

RSpec.describe RailsTablePreferences::PackageVerifier do
  describe ".call" do
    it "reports success when all required paths are packaged" do
      verifier = described_class.new(gem_path: "dummy.gem", required_paths: %w[README.md CHANGELOG.md])
      allow(verifier).to receive(:packaged_files).and_return(%w[CHANGELOG.md README.md docs/index.md])

      result = verifier.call

      expect(result[:ok]).to eq(true)
      expect(result[:missing]).to eq([])
    end

    it "reports missing required paths" do
      verifier = described_class.new(gem_path: "dummy.gem", required_paths: %w[README.md CHANGELOG.md docs/index.md])
      allow(verifier).to receive(:packaged_files).and_return(%w[README.md])

      result = verifier.call

      expect(result[:ok]).to eq(false)
      expect(result[:missing]).to eq(%w[CHANGELOG.md docs/index.md])
    end

    it "reports success when package exports point to packaged JavaScript entrypoints" do
      verifier = described_class.new(gem_path: "dummy.gem", required_paths: %w[package.json])
      allow(verifier).to receive(:packaged_files).and_return(
        %w[
          app/javascript/rails_table_preferences/controller.js
          app/javascript/rails_table_preferences/index.js
          package.json
        ]
      )
      allow(verifier).to receive(:packaged_file_contents).with("package.json").and_return(package_json)

      result = verifier.call

      expect(result[:ok]).to eq(true)
      expect(result[:missing_package_export_targets]).to eq([])
      expect(result[:package_json_errors]).to eq([])
    end

    it "reports package exports that point to files missing from the built gem" do
      verifier = described_class.new(gem_path: "dummy.gem", required_paths: %w[package.json])
      allow(verifier).to receive(:packaged_files).and_return(
        %w[
          app/javascript/rails_table_preferences/index.js
          package.json
        ]
      )
      allow(verifier).to receive(:packaged_file_contents).with("package.json").and_return(package_json)

      result = verifier.call

      expect(result[:ok]).to eq(false)
      expect(result[:missing]).to eq([])
      expect(result[:missing_package_export_targets]).to eq(
        [
          {
            export: "./controller",
            target: "app/javascript/rails_table_preferences/controller.js"
          }
        ]
      )
    end

    it "reports invalid packaged package metadata" do
      verifier = described_class.new(gem_path: "dummy.gem", required_paths: %w[package.json])
      allow(verifier).to receive(:packaged_files).and_return(%w[package.json])
      allow(verifier).to receive(:packaged_file_contents).with("package.json").and_return("{")

      result = verifier.call

      expect(result[:ok]).to eq(false)
      expect(result[:package_json_errors].join).to include("package.json could not be parsed")
    end
  end

  describe "required packaged docs" do
    it "keeps the main README/docs index entrypoints in the package guard" do
      expected_docs = %w[
        docs/index.md
        docs/quick_start.md
        docs/resource_tables.md
        docs/resource_table_formatter_contract.md
        docs/decision_guide.md
        docs/scoped_presets.md
        docs/fixed_columns_and_groups.md
        docs/export_integration.md
        docs/accessibility.md
        docs/visual_overview.md
        docs/demo.md
        docs/sandbox.md
        docs/examples.md
        docs/troubleshooting.md
        docs/manual_qa.md
        docs/release_checklist.md
        docs/package_verification.md
        docs/controller_integration.md
        docs/filter_metadata.md
        docs/filter_adapters.md
        docs/javascript_entrypoints.md
        docs/javascript_controller.md
      ]

      expect(described_class::REQUIRED_PATHS).to include(*expected_docs)
    end
  end

  def package_json
    {
      "exports" => {
        "." => "./app/javascript/rails_table_preferences/index.js",
        "./controller" => "./app/javascript/rails_table_preferences/controller.js"
      }
    }.to_json
  end
end
