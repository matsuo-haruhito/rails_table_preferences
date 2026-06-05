import RailsTablePreferencesBaseController from "../controllers/rails_table_preferences_controller"

export default class RailsTablePreferencesController extends RailsTablePreferencesBaseController {
  static targets = [...RailsTablePreferencesBaseController.targets, "dirtyState"]

  static values = {
    ...RailsTablePreferencesBaseController.values,
    filterOperatorLabels: { type: Object, default: {} },
    dirtyStateLabel: { type: String, default: "未保存の変更があります。" }
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
    this.installDirtyStateTracking()
    this.markEditorClean()
  }

  disconnect() {
    this.uninstallDirtyStateTracking()
    super.disconnect()
  }

  applyFromEditor(event) {
    const wasBusy = this.busy
    const result = super.applyFromEditor(event)
    this.updateDirtyStateFromEditor()
    if (!wasBusy) {
      this.clearSuccessfulStatus()
      this.dispatchPreferenceEvent("applied", { action: "apply" })
    }
    return result
  }

  resetEditor(event) {
    const wasBusy = this.busy
    const result = super.resetEditor(event)
    this.updateDirtyStateFromEditor()
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
    this.updateDirtyStateFromEditor()
    this.clearSuccessfulStatus()
  }

  autoFitColumnFromHandle(event) {
    super.autoFitColumnFromHandle(event)
    this.updateDirtyStateFromEditor()
    this.clearSuccessfulStatus()
  }

  dragTableColumnOver(event) {
    super.dragTableColumnOver(event)
    this.clearSuccessfulStatus()
  }

  dropTableColumn(event) {
    super.dropTableColumn(event)
    this.updateDirtyStateFromEditor()
    this.clearSuccessfulStatus()
  }

  endTableColumnDrag(event) {
    super.endTableColumnDrag(event)
    this.updateDirtyStateFromEditor()
    this.clearSuccessfulStatus()
  }

  toggleSortFromHeader(event, cell, column) {
    super.toggleSortFromHeader(event, cell, column)
    this.updateDirtyStateFromEditor()
    this.clearSuccessfulStatus()
  }

  applyFilterPanel(key, panel) {
    super.applyFilterPanel(key, panel)
    this.updateDirtyStateFromEditor()
    this.clearSuccessfulStatus()
  }

  clearFilter(key) {
    super.clearFilter(key)
    this.updateDirtyStateFromEditor()
    this.clearSuccessfulStatus()
  }

  applyPreferencePayload(payload) {
    super.applyPreferencePayload(payload)
    this.markEditorClean()
  }

  renderEditor() {
    super.renderEditor()
    this.updateDirtyStateFromEditor()
  }

  refreshEditorOrderInputs() {
    super.refreshEditorOrderInputs()
    this.updateDirtyStateFromEditor()
  }

  installDirtyStateTracking() {
    this.ensureDirtyStateElement()
    if (this.dirtyStateTrackingInstalled) return
    if (!this.hasEditorRowsTarget) return

    this.boundUpdateDirtyStateFromEditor = this.updateDirtyStateFromEditor.bind(this)
    this.editorRowsTarget.addEventListener("input", this.boundUpdateDirtyStateFromEditor)
    this.editorRowsTarget.addEventListener("change", this.boundUpdateDirtyStateFromEditor)
    this.dirtyStateTrackingInstalled = true
  }

  uninstallDirtyStateTracking() {
    if (!this.dirtyStateTrackingInstalled || !this.hasEditorRowsTarget || !this.boundUpdateDirtyStateFromEditor) return

    this.editorRowsTarget.removeEventListener("input", this.boundUpdateDirtyStateFromEditor)
    this.editorRowsTarget.removeEventListener("change", this.boundUpdateDirtyStateFromEditor)
    this.boundUpdateDirtyStateFromEditor = null
    this.dirtyStateTrackingInstalled = false
  }

  ensureDirtyStateElement() {
    if (this.hasDirtyStateTarget) return

    const element = document.createElement("p")
    element.className = "rails-table-preferences-editor__hint rails-table-preferences-editor__dirty-state"
    element.dataset.railsTablePreferencesTarget = "dirtyState"
    element.setAttribute("aria-live", "polite")
    element.setAttribute("aria-atomic", "true")
    element.hidden = true

    if (this.hasStatusTarget) {
      this.statusTarget.parentNode.insertBefore(element, this.statusTarget)
    } else {
      this.element.appendChild(element)
    }
  }

  markEditorClean() {
    this.savedSettingsSnapshot = this.normalizedSettingsSignature(this.settingsFromEditor())
    this.updateDirtyStateFromEditor()
  }

  updateDirtyStateFromEditor() {
    if (!this.hasDirtyStateTarget || !this.hasEditorRowsTarget) return
    if (!this.savedSettingsSnapshot) this.savedSettingsSnapshot = this.normalizedSettingsSignature(this.settingsFromEditor())

    const dirty = this.normalizedSettingsSignature(this.settingsFromEditor()) !== this.savedSettingsSnapshot
    this.dirtyStateTarget.hidden = !dirty
    this.dirtyStateTarget.textContent = dirty ? this.dirtyStateLabelValue : ""
  }

  normalizedSettingsSignature(settings) {
    return JSON.stringify(this.normalizeSettingsValue(settings))
  }

  normalizeSettingsValue(value) {
    if (Array.isArray(value)) return value.map((item) => this.normalizeSettingsValue(item))
    if (value && typeof value === "object") {
      return Object.keys(value).sort().reduce((normalized, key) => {
        normalized[key] = this.normalizeSettingsValue(value[key])
        return normalized
      }, {})
    }
    return value ?? null
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
    if (!this.currentPreferenceEditable) return this.createPresetFromEditor(event)

    const result = await this.withPreferenceAction("save", () => super.save(event))
    if (result !== null) {
      this.markEditorClean()
      this.dispatchPreferenceEvent("saved", { action: "save" })
    } else {
      this.updateDirtyStateFromEditor()
    }
    return result
  }

  async createPresetFromEditor(event) {
    const result = await this.withPreferenceAction("create", () => super.createPresetFromEditor(event))
    if (result !== null) {
      this.markEditorClean()
      this.dispatchPreferenceEvent("saved", { action: "create" })
    } else {
      this.updateDirtyStateFromEditor()
    }
    return result
  }

  async selectPreset(event) {
    const result = await this.withPreferenceAction("load", () => super.selectPreset(event))
    if (result !== null) {
      this.markEditorClean()
      this.dispatchPreferenceEvent("loaded", { action: "load" })
    } else {
      this.updateDirtyStateFromEditor()
    }
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
        this.markEditorClean()
        await this.refreshPresetOptions()
      }, {
        busyLabel: this.deletingStatusLabelValue,
        successLabel: this.deletedStatusLabelValue,
        errorLabel: this.deletingFailedStatusLabelValue
      })
    })
    if (result !== null) this.dispatchPreferenceEvent("deleted", { action: "delete", name: deletedName })
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

  installResizeHandles() {
    super.installResizeHandles()
    this.element.querySelectorAll("[data-rails-table-preferences-resize-handle]").forEach((handle) => {
      if (handle.dataset.railsTablePreferencesKeyboardAutoFitInstalled === "true") return
      handle.dataset.railsTablePreferencesKeyboardAutoFitInstalled = "true"
      handle.addEventListener("keydown", this.autoFitColumnFromResizeHandleKeyboard.bind(this))
    })
  }

  autoFitColumnFromResizeHandleKeyboard(event) {
    if (!this.isResizeHandleAutoFitKey(event)) return
    event.preventDefault()
    this.autoFitColumnFromHandle(event)
  }

  isResizeHandleAutoFitKey(event) {
    return event.key === "Enter" || event.key === " " || event.key === "Spacebar"
  }

  clearFiltersAndSorts(event) {
    if (this.busy) return
    if (event) event.preventDefault()
    this.settingsValue = { ...this.settingsValue, filters: {}, sorts: [] }
    this.closeFilterPanel()
    this.apply()
  }

  openFilterPanel(headerCell, column, button = headerCell.querySelector("[data-rails-table-preferences-filter-button]")) {
    super.openFilterPanel(headerCell, column, button)
    if (!this.filterPanel) return

    this.filterPanel.setAttribute("role", "group")
    this.filterPanel.setAttribute("aria-labelledby", this.filterPanelTitleId(column.key))
  }

  filterPanelHtml(column) {
    return super.filterPanelHtml(column).replace(
      'class="rails-table-preferences-filter-panel__title"',
      `id="${this.filterPanelTitleId(column.key)}" class="rails-table-preferences-filter-panel__title"`
    )
  }

  filterPanelTitleId(key) {
    return `${this.filterPanelId(key)}-title`
  }

  filterValueHtml(filter, condition, selectedOperator) {
    if (filter.type === "select" && Array.isArray(filter.options) && !["blank", "present", "true", "false"].includes(selectedOperator)) {
      const values = new Set(Array(condition.values || condition.value || []).map(String))
      const optionsHtml = filter.options.map((option) => {
        const value = this.selectFilterOptionValue(option)
        const label = this.selectFilterOptionLabel(option, value)
        return `<option value="${this.escapeHtml(value)}" ${values.has(String(value)) ? "selected" : ""}>${this.escapeHtml(label)}</option>`
      }).join("")
      return `<label class="rails-table-preferences-filter-panel__field">${this.escapeHtml(this.filterValueLabelValue)}<select data-field="values" multiple>${optionsHtml}</select></label>`
    }

    return super.filterValueHtml(filter, condition, selectedOperator)
  }

  selectFilterOptionValue(option) {
    if (option && typeof option === "object" && !Array.isArray(option)) {
      return String(option.value ?? option.label ?? "")
    }

    return String(option ?? "")
  }

  selectFilterOptionLabel(option, fallbackValue = this.selectFilterOptionValue(option)) {
    if (option && typeof option === "object" && !Array.isArray(option)) {
      return String(option.label ?? option.value ?? fallbackValue)
    }

    return String(option ?? "")
  }

  filterOperatorText(operator) {
    const key = String(operator)
    const override = this.filterOperatorLabelsValue?.[key]
    if (override !== undefined && override !== null && String(override).trim() !== "") return String(override)
    return super.filterOperatorText(key)
  }
}
