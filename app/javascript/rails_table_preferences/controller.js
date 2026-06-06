import RailsTablePreferencesBaseController from "../controllers/rails_table_preferences_controller"

export default class RailsTablePreferencesController extends RailsTablePreferencesBaseController {
  static values = {
    ...RailsTablePreferencesBaseController.values,
    filterOperatorLabels: { type: Object, default: {} }
  }

  filterValueHtml(filter, condition, selectedOperator) {
    if (["blank", "present", "true", "false"].includes(selectedOperator)) return ""
    if (selectedOperator === "between") {
      const inputType = this.filterInputType(filter)
      const fromPlaceholder = this.filterPlaceholderAttribute(filter.from_placeholder)
      const toPlaceholder = this.filterPlaceholderAttribute(filter.to_placeholder)
      return `
        <label class="rails-table-preferences-filter-panel__field">${this.escapeHtml(this.filterFromLabelValue)}<input type="${inputType}" data-field="from" value="${this.escapeHtml(condition.from ?? "")}"${fromPlaceholder}></label>
        <label class="rails-table-preferences-filter-panel__field">${this.escapeHtml(this.filterToLabelValue)}<input type="${inputType}" data-field="to" value="${this.escapeHtml(condition.to ?? "")}"${toPlaceholder}></label>
      `
    }
    if (filter.type === "select" && Array.isArray(filter.options)) {
      const values = new Set(Array(condition.values || condition.value || []).map(String))
      return `<label class="rails-table-preferences-filter-panel__field">${this.escapeHtml(this.filterValueLabelValue)}<select data-field="values" multiple>${filter.options.map((option) => `<option value="${this.escapeHtml(option)}" ${values.has(String(option)) ? "selected" : ""}>${this.escapeHtml(option)}</option>`).join("")}</select></label>`
    }
    const placeholder = this.filterPlaceholderAttribute(filter.placeholder)
    return `<label class="rails-table-preferences-filter-panel__field">${this.escapeHtml(this.filterValueLabelValue)}<input type="${this.filterInputType(filter)}" data-field="value" value="${this.escapeHtml(condition.value ?? "")}"${placeholder}></label>`
  }

  filterPlaceholderAttribute(value) {
    const text = String(value ?? "").trim()
    if (!text) return ""
    return ` placeholder="${this.escapeHtml(text)}"`
  }

  connect() {
    this.statusState = "idle"
    super.connect()
  }

  applyFromEditor(event) {
    const wasBusy = this.busy
    const result = super.applyFromEditor(event)
    if (!wasBusy) {
      this.clearSuccessfulStatus()
      this.dispatchPreferenceEvent("applied", { action: "apply" })
    }
    return result
  }

  resetEditor(event) {
    const wasBusy = this.busy
    const result = super.resetEditor(event)
    if (!wasBusy) this.clearSuccessfulStatus()
    return result
  }

  buildEditorRow(column) {
    const row = super.buildEditorRow(column)
    row.addEventListener("input", () => this.clearSuccessfulStatus())
    row.addEventListener("change", () => this.clearSuccessfulStatus())
    return row
  }

  dragEditorRowOver(event) {
    super.dragEditorRowOver(event)
    this.clearSuccessfulStatus()
  }

  dropEditorRow(event) {
    super.dropEditorRow(event)
    this.clearSuccessfulStatus()
  }

  dragEditorRowEnd(event) {
    super.dragEditorRowEnd(event)
    this.clearSuccessfulStatus()
  }

  resizeColumn(event) {
    super.resizeColumn(event)
    this.clearSuccessfulStatus()
  }

  autoFitColumnFromHandle(event) {
    super.autoFitColumnFromHandle(event)
    this.clearSuccessfulStatus()
  }

  dragTableColumnOver(event) {
    super.dragTableColumnOver(event)
    this.clearSuccessfulStatus()
  }

  dropTableColumn(event) {
    super.dropTableColumn(event)
    this.clearSuccessfulStatus()
  }

  endTableColumnDrag(event) {
    super.endTableColumnDrag(event)
    this.clearSuccessfulStatus()
  }

  toggleSortFromHeader(event, cell, column) {
    super.toggleSortFromHeader(event, cell, column)
    this.clearSuccessfulStatus()
  }

  applyFilterPanel(key, panel) {
    super.applyFilterPanel(key, panel)
    this.clearSuccessfulStatus()
  }

  clearFilter(key) {
    super.clearFilter(key)
    this.clearSuccessfulStatus()
  }

  setStatus(message, state = "idle") {
    this.statusState = message ? state : "idle"
    super.setStatus(message)
  }

  clearSuccessfulStatus() {
    if (this.statusState === "success") this.setStatus("")
  }

  async withBusyStatus(callback, { busyLabel, successLabel, errorLabel = this.operationFailedStatusLabelValue } = {}) {
    if (this.busy) return null
    this.setBusyState(true)
    if (busyLabel) this.setStatus(busyLabel, "busy")

    try {
      const result = await callback()
      if (successLabel) this.setStatus(successLabel, "success")
      return result
    } catch (error) {
      this.handleOperationError(error, errorLabel)
      return null
    } finally {
      this.setBusyState(false)
    }
  }

  async save(event) {
    if (this.busy) return null
    if (!this.currentPreferenceEditable) return this.createPresetFromEditor(event)

    const result = await this.withPreferenceAction("save", () => super.save(event))
    if (result !== null && this.statusState === "success") this.dispatchPreferenceEvent("saved", { action: "save" })
    return result
  }

  async createPresetFromEditor(event) {
    if (this.busy) return null

    const result = await this.withPreferenceAction("create", () => super.createPresetFromEditor(event))
    if (result !== null && this.statusState === "success") this.dispatchPreferenceEvent("saved", { action: "create" })
    return result
  }

  async selectPreset(event) {
    if (this.busy) return null

    const result = await this.withPreferenceAction("load", () => super.selectPreset(event))
    if (result !== null && this.statusState === "success") this.dispatchPreferenceEvent("loaded", { action: "load" })
    return result
  }

  async deletePreset(event) {
    if (event) event.preventDefault()
    if (!this.currentPreferenceEditable) return undefined
    if (!this.confirmDeletePreset()) return undefined

    const deletedName = this.currentPresetName
    const result = await this.withPreferenceAction("delete", async () => {
      return this.withBusyStatus(async () => {
        const response = await fetch(this.preferenceUrl(deletedName), {
          method: "DELETE",
          headers: { "Accept": "application/json", "X-CSRF-Token": this.csrfToken }
        })
        if (!response.ok && response.status !== 204) throw new Error(`Failed to delete table preference preset: ${response.status}`)
        this.nameValue = "default"
        this.urlValue = this.preferenceUrl("default")
        this.currentPreferenceEditable = true
        this.setPresetNameInput("default")
        this.setDefaultPresetInput(false)
        this.settingsValue = this.defaultSettings
        this.closeFilterPanel()
        this.renderEditor()
        this.apply()
        this.syncPresetEditingState()
        await this.refreshPresetOptions()
      }, {
        busyLabel: this.deletingStatusLabelValue,
        successLabel: this.deletedStatusLabelValue,
        errorLabel: this.deletingFailedStatusLabelValue
      })
    })
    if (result !== null && this.statusState === "success") this.dispatchPreferenceEvent("deleted", { action: "delete", name: deletedName })
    return result
  }

  async refreshPresetOptionsOnConnect() {
    return this.withPreferenceAction("load-presets", () => super.refreshPresetOptionsOnConnect())
  }

  handleOperationError(error, message = this.operationFailedStatusLabelValue) {
    super.handleOperationError(error, message)
    this.statusState = "error"
    this.dispatchPreferenceEvent("error", {
      action: this.currentPreferenceAction || "operation",
      message: message || this.operationFailedStatusLabelValue
    })
  }

  withPreferenceAction(action, callback) {
    const previousAction = this.currentPreferenceAction
    this.currentPreferenceAction = action
    const restore = () => { this.currentPreferenceAction = previousAction }

    try {
      const result = callback()
      if (result && typeof result.then === "function") return result.finally(restore)
      restore()
      return result
    } catch (error) {
      restore()
      throw error
    }
  }

  dispatchPreferenceEvent(name, detail = {}) {
    this.dispatch(name, { detail: this.preferenceEventDetail(detail) })
  }

  preferenceEventDetail(detail = {}) {
    return {
      tableKey: this.tableKeyValue,
      name: this.currentPresetName,
      settings: this.settingsValue,
      ...detail
    }
  }

  installSortControls() {
    this.headerCells.forEach((cell) => {
      if (cell.dataset.railsTablePreferencesSortInstalled === "true") return
      if (cell.hasAttribute("title") && cell.title.trim() !== "") {
        cell.dataset.railsTablePreferencesHostTitle = cell.title
      }
    })

    super.installSortControls()
  }

  syncSortStates() {
    super.syncSortStates()

    this.headerCells.forEach((cell) => {
      if (cell.dataset.railsTablePreferencesHostTitle !== undefined) {
        cell.title = cell.dataset.railsTablePreferencesHostTitle
      }
    })
  }

  selectFilterOptionValue(option) {
    if (option && typeof option === "object" && !Array.isArray(option)) {
      return option.value ?? option.id ?? option.key ?? option.label ?? option.name ?? ""
    }
    return option
  }

  selectFilterOptionLabel(option) {
    if (option && typeof option === "object" && !Array.isArray(option)) {
      const label = option.label ?? option.name ?? option.text ?? option.value ?? option.id ?? option.key ?? ""
      return label
    }
    return option
  }
}
