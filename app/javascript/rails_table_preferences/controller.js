import RailsTablePreferencesBaseController from "../controllers/rails_table_preferences_controller"

export default class RailsTablePreferencesController extends RailsTablePreferencesBaseController {
  static targets = [...RailsTablePreferencesBaseController.targets, "dirtyState"]

  static values = {
    ...RailsTablePreferencesBaseController.values,
    filterOperatorLabels: { type: Object, default: {} },
    dirtyStateLabel: { type: String, default: "未保存の変更があります。" }
  }

  connect() {
    super.connect()
    this.installDirtyStateTracking()
    this.markEditorClean()
  }

  disconnect() {
    this.uninstallDirtyStateTracking()
    super.disconnect()
  }

  applyFromEditor(event) {
    const result = super.applyFromEditor(event)
    this.updateDirtyStateFromEditor()
    return result
  }

  async saveFromEditor(event) {
    const result = await super.saveFromEditor(event)
    this.updateDirtyStateFromEditor()
    return result
  }

  async createPresetFromEditor(event) {
    const result = await super.createPresetFromEditor(event)
    this.updateDirtyStateFromEditor()
    return result
  }

  async save(event) {
    const result = await super.save(event)
    this.updateDirtyStateFromEditor()
    return result
  }

  resetEditor(event) {
    const result = super.resetEditor(event)
    this.updateDirtyStateFromEditor()
    return result
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

  resizeColumn(event) {
    const result = super.resizeColumn(event)
    this.updateDirtyStateFromEditor()
    return result
  }

  autoFitColumnFromHandle(event) {
    const result = super.autoFitColumnFromHandle(event)
    this.updateDirtyStateFromEditor()
    return result
  }

  dropTableColumn(event) {
    const result = super.dropTableColumn(event)
    this.updateDirtyStateFromEditor()
    return result
  }

  endTableColumnDrag(event) {
    const result = super.endTableColumnDrag(event)
    this.updateDirtyStateFromEditor()
    return result
  }

  applyFilterPanel(key, panel) {
    const result = super.applyFilterPanel(key, panel)
    this.updateDirtyStateFromEditor()
    return result
  }

  clearFilter(key) {
    const result = super.clearFilter(key)
    this.updateDirtyStateFromEditor()
    return result
  }

  toggleSortFromHeader(event, cell, column) {
    const result = super.toggleSortFromHeader(event, cell, column)
    this.updateDirtyStateFromEditor()
    return result
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

  filterOperatorText(operator) {
    const key = String(operator)
    const override = this.filterOperatorLabelsValue?.[key]
    if (override !== undefined && override !== null && String(override).trim() !== "") return String(override)
    return super.filterOperatorText(key)
  }
}
