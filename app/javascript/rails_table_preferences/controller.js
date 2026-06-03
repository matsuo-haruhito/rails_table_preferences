import RailsTablePreferencesBaseController from "../controllers/rails_table_preferences_controller"

export default class RailsTablePreferencesController extends RailsTablePreferencesBaseController {
  static values = {
    ...RailsTablePreferencesBaseController.values,
    filterOperatorLabels: { type: Object, default: {} }
  }

  applyFromEditor(event) {
    const wasBusy = this.busy
    const result = super.applyFromEditor(event)
    if (!wasBusy) this.dispatchPreferenceEvent("applied", { action: "apply" })
    return result
  }

  async save(event) {
    if (!this.currentPreferenceEditable) return this.createPresetFromEditor(event)

    const result = await this.withPreferenceAction("save", () => super.save(event))
    if (result !== null) this.dispatchPreferenceEvent("saved", { action: "save" })
    return result
  }

  async createPresetFromEditor(event) {
    const result = await this.withPreferenceAction("create", () => super.createPresetFromEditor(event))
    if (result !== null) this.dispatchPreferenceEvent("saved", { action: "create" })
    return result
  }

  async selectPreset(event) {
    const result = await this.withPreferenceAction("load", () => super.selectPreset(event))
    if (result !== null) this.dispatchPreferenceEvent("loaded", { action: "load" })
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
    if (result !== null) this.dispatchPreferenceEvent("deleted", { action: "delete", name: deletedName })
    return result
  }

  async refreshPresetOptionsOnConnect() {
    return this.withPreferenceAction("load-presets", () => super.refreshPresetOptionsOnConnect())
  }

  handleOperationError(error, message = this.operationFailedStatusLabelValue) {
    super.handleOperationError(error, message)
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

  positionFilterPanel(panel, headerCell) {
    const rect = headerCell.getBoundingClientRect()
    const viewportMargin = 8
    const panelWidth = panel.offsetWidth || panel.getBoundingClientRect().width || 0
    const minLeft = window.scrollX + viewportMargin
    const maxLeft = window.scrollX + window.innerWidth - panelWidth - viewportMargin
    const desiredLeft = window.scrollX + rect.left
    const left = panelWidth > 0 ? Math.max(minLeft, Math.min(desiredLeft, maxLeft)) : desiredLeft

    panel.style.position = "absolute"
    panel.style.top = `${window.scrollY + rect.bottom + 4}px`
    panel.style.left = `${left}px`
    panel.style.maxWidth = `calc(100vw - ${viewportMargin * 2}px)`
    panel.style.zIndex = "1000"
  }

  filterOperatorText(operator) {
    const key = String(operator)
    const override = this.filterOperatorLabelsValue?.[key]
    if (override !== undefined && override !== null && String(override).trim() !== "") return String(override)
    return super.filterOperatorText(key)
  }
}
