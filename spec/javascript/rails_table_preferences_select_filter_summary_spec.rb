# frozen_string_literal: true

RSpec.describe "RailsTablePreferences package select filter summary source" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:entrypoint_source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/preset_select_recovery.js")) }
  let(:package_controller_source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }

  it "resolves package exported select summaries through option labels and raw fallbacks" do
    expect(entrypoint_source).to include("filterConditionSummaryForColumn(column, condition = {})")
    expect(entrypoint_source).to include('String(filter.type) !== "select" || !Array.isArray(filter.options)')
    expect(entrypoint_source).to include("return super.filterConditionSummary(condition)")
    expect(entrypoint_source).to include("const values = this.selectFilterSummaryValues(condition)")
    expect(entrypoint_source).to include("this.selectFilterOptionSummaryLabel(filter, value)")
    expect(entrypoint_source).to include("this.filterSummaryValues(labels)")
    expect(entrypoint_source).to include("const option = (filter.options || []).find((candidate) => this.selectFilterOptionValue(candidate) === rawValue)")
    expect(entrypoint_source).to include("if (!option) return rawValue")
    expect(entrypoint_source).to include("return this.selectFilterOptionLabel(option, rawValue)")
  end

  it "keeps scalar, empty, and operator-only summary paths stable" do
    expect(entrypoint_source).to include("if (Array.isArray(condition.values)) return condition.values")
    expect(entrypoint_source).to include('String(condition.value) !== ""')
    expect(entrypoint_source).to include('if (["blank", "present", "true", "false"].includes(operator)) return operatorText')
  end

  it "uses the existing package value/label helpers without moving behavior into the copied controller" do
    expect(package_controller_source).to include("selectFilterOptionValue(option)")
    expect(package_controller_source).to include("selectFilterOptionLabel(option, fallbackValue = this.selectFilterOptionValue(option))")
    expect(entrypoint_source).to include('import RailsTablePreferencesController from "./controller.js"')
  end
end
