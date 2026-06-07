# frozen_string_literal: true

RSpec.describe "rails_table_preferences/controller package entrypoint" do
  let(:source_path) do
    File.expand_path("../../app/javascript/rails_table_preferences/controller.js", __dir__)
  end

  let(:source) { File.read(source_path) }

  it "keeps owner preset options labelled with the configured scope context" do
    expect(source).to include("buildPresetOption(preset)")
    expect(source).to include("const option = super.buildPresetOption(preset)")
    expect(source).to include('const scopeType = preset.scope_type || "owner"')
    expect(source).to include("const scopeLabel = preset.scope_label || this.scopeFallbackLabel(scopeType)")
    expect(source).to include('const scopeMark = scopeLabel ? ` [${scopeLabel}]` : ""')
    expect(source).to include('option.textContent = `${name}${scopeMark}${defaultMark}`')
  end
end
