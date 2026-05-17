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
  end
end
