import RailsTablePreferencesController from "./controller.js"

export default class RailsTablePreferencesPresetSelectRecoveryController extends RailsTablePreferencesController {
  static values = {
    ...(RailsTablePreferencesController.values || {}),
    presetSearchClearLabel: { type: String, default: "検索をクリア" }
  }

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

  positionFilterPanel(panel, headerCell) {
    super.positionFilterPanel(panel, headerCell)

    const rect = headerCell.getBoundingClientRect()
    const viewportMargin = 8
    const panelTop = window.scrollY + rect.bottom + 4
    const viewportBottom = window.scrollY + window.innerHeight - viewportMargin
    const availableHeight = Math.max(viewportMargin, viewportBottom - panelTop)

    panel.style.maxHeight = `${availableHeight}px`
    panel.style.overflowY = "auto"
  }

  ensurePresetSearchControl() {
    super.ensurePresetSearchControl()
    if (!this.presetSearchControl || this.presetSearchClearButton) return

    const button = document.createElement("button")
    button.type = "button"
    button.className = "rails-table-preferences-editor__search-clear"
    button.dataset.railsTablePreferencesPresetSearchClear = "true"
    button.textContent = this.presetSearchClearLabelValue || "検索をクリア"
    button.setAttribute("aria-label", this.presetSearchClearLabelValue || "検索をクリア")
    button.hidden = true
    button.addEventListener("click", (event) => this.clearPresetSearchQuery(event))

    const emptyMessage = this.presetSearchEmptyMessage
    if (emptyMessage?.parentNode) emptyMessage.parentNode.insertBefore(button, emptyMessage)
    else this.presetSearchControl.appendChild(button)
  }

  syncPresetSearchState({ query, visibleCount, enabled }) {
    super.syncPresetSearchState({ query, visibleCount, enabled })

    const hasQuery = enabled && Boolean(query)
    if (this.presetSearchClearButton) {
      this.presetSearchClearButton.hidden = !hasQuery
      this.presetSearchClearButton.disabled = this.busy || !hasQuery
    }
  }

  clearPresetSearchQuery(event) {
    if (event) event.preventDefault()
    if (this.busy) return

    const input = this.presetSearchInput
    if (!input) return

    input.value = ""
    this.renderPresetOptions()
    if (typeof input.focus === "function") input.focus()
  }

  get presetSearchClearButton() {
    return this.presetSearchControl?.querySelector("[data-rails-table-preferences-preset-search-clear]")
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
