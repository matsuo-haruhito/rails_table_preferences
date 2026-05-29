# frozen_string_literal: true

require "spec_helper"
require "rails_table_preferences/package_verifier"

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

    it "guards representative README-linked docs and visual assets" do
      expect(described_class::REQUIRED_PATHS).to include(
        "docs/visual_overview.md",
        "docs/images/visual-overview-editor-and-table.svg",
        "docs/quick_start.md",
        "docs/demo.md",
        "docs/export_integration.md",
        "docs/accessibility.md",
        "docs/troubleshooting.md",
        "docs/release_checklist.md"
      )
    end
  end

  def repository_root
    Pathname.new(File.expand_path("../..", __dir__))
  end
end
