# frozen_string_literal: true

RSpec.describe "RailsTablePreferences package select option search threshold" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }

  it "declares a package entrypoint root value with the existing default" do
    expect(source).to include("selectFilterOptionSearchThreshold: { type: Number, default: 8 }")
  end

  it "uses the normalized threshold to decide whether option search is rendered" do
    expect(source).to include("options.length < this.selectFilterOptionSearchThreshold")
    expect(source).to include("get selectFilterOptionSearchThreshold()")
    expect(source).to include("railsTablePreferencesSelectFilterOptionSearchThresholdValue")
    expect(source).to include("if (rawValue !== undefined && String(rawValue).trim() === \"\") return 8")
    expect(source).to include("if (!Number.isFinite(threshold)) return 8")
    expect(source).to include("return Math.floor(threshold)")
  end

  it "keeps scalar and label-value option handling on the existing package path" do
    expect(source).to include("const value = this.selectFilterOptionValue(option)")
    expect(source).to include("const label = this.selectFilterOptionLabel(option, value)")
    expect(source).to include("return String(option.value ?? option.label ?? \"\")")
    expect(source).to include("return String(option.label ?? option.value ?? fallbackValue)")
  end
end
