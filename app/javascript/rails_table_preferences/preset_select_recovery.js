import RailsTablePreferencesController from "./controller.js"

export default class RailsTablePreferencesPresetSelectRecoveryController extends RailsTablePreferencesController {
  filterButtonLabel(column, condition = {}) {
    const columnLabel = column?.label || column?.key || this.filterLabelValue
    const baseLabel = `${this.filterLabelValue}: ${columnLabel}`
    const summary = this.filterConditionSummaryForColumn(column, condition)
    return summary ? `${baseLabel} (${summary})` : baseLabel
  }

  filterConditionSummaryForColumn(column, condition = {}) {
    const filter = column?.filter || {}
    if (String(filter.type) !== "select" || !Array.isArray(filter.options)) {
      return super.filterConditionSummary(condition)
    }

    const operator = String(condition?.operator || "").trim()
    if (!operator) return ""
    const operatorText = this.filterOperatorText(operator)
    if (["blank", "present", "true", "false"].includes(operator)) return operatorText

    const values = this.selectFilterSummaryValues(condition)
    if (values.length === 0) return operatorText

    const labels = values
      .map((value) => this.selectFilterOptionSummaryLabel(filter, value))
      .map((value) => this.filterSummaryText(value))
      .filter(Boolean)

    return labels.length > 0 ? `${operatorText}: ${this.filterSummaryValues(labels)}` : operatorText
  }

  selectFilterSummaryValues(condition = {}) {
    if (Array.isArray(condition.values)) return condition.values
    if (condition.value !== undefined && condition.value !== null && String(condition.value) !== "") return [condition.value]
    return []
  }

  selectFilterOptionSummaryLabel(filter, value) {
    const rawValue = String(value ?? "")
    const option = (filter.options || []).find((candidate) => this.selectFilterOptionValue(candidate) === rawValue)
    if (!option) return rawValue
    return this.selectFilterOptionLabel(option, rawValue)
  }

  async selectPreset(event) {
    if (this.busy) return null

    const appliedPresetName = this.nameValue || this.currentPresetName
    const result = await super.selectPreset(event)

    if (this.statusState !== "success") this.restorePresetSelectToAppliedPreset(appliedPresetName)
    return result
  }

  restorePresetSelectToAppliedPreset(name) {
    if (!this.hasPresetSelectTarget) return

    this.presetSelectTarget.value = name || "default"
    this.syncDeletePresetButtonContext()
  }
}
