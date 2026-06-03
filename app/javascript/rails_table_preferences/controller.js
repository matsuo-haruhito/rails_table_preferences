import RailsTablePreferencesBaseController from "../controllers/rails_table_preferences_controller"

export default class RailsTablePreferencesController extends RailsTablePreferencesBaseController {
  static values = {
    ...RailsTablePreferencesBaseController.values,
    filterOperatorLabels: { type: Object, default: {} },
    editorSearchLabel: { type: String, default: "列を検索" },
    editorSearchPlaceholder: { type: String, default: "列名で絞り込み" },
    editorNoSearchResultsLabel: { type: String, default: "一致する列はありません。検索語を変更してください。" },
    moveUpLabel: { type: String, default: "上へ移動" },
    moveDownLabel: { type: String, default: "下へ移動" }
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

  renderEditor() {
    super.renderEditor()
    this.ensureEditorSearchControl()
    this.syncEditorSearchResults()
    this.syncEditorMoveButtons()
  }

  buildEditorRow(column) {
    const row = super.buildEditorRow(column)
    row.dataset.railsTablePreferencesEditorSearchText = [column.label, column.key, column.group].filter(Boolean).join(" ").toLowerCase()
    row.insertBefore(this.buildEditorMoveControls(), row.querySelector(".rails-table-preferences-editor__visible"))
    return row
  }

  buildEditorMoveControls() {
    const controls = document.createElement("div")
    controls.className = "rails-table-preferences-editor__row-actions"
    controls.setAttribute("aria-label", this.orderLabelValue)

    const upButton = this.buildEditorMoveButton("up", this.moveUpLabelValue, "↑")
    const downButton = this.buildEditorMoveButton("down", this.moveDownLabelValue, "↓")
    controls.append(upButton, downButton)
    return controls
  }

  buildEditorMoveButton(direction, label, text) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "rails-table-preferences-editor__move-button"
    button.dataset.railsTablePreferencesMoveDirection = direction
    button.setAttribute("aria-label", label)
    button.title = label
    button.textContent = text
    button.addEventListener("click", (event) => this.moveEditorRow(event, direction === "up" ? -1 : 1))
    return button
  }

  moveEditorRow(event, direction) {
    if (this.busy) return
    if (event) event.preventDefault()
    const row = event.currentTarget.closest("[data-rails-table-preferences-column-key]")
    if (!row) return

    const rows = this.editorRowsForMovement
    const index = rows.indexOf(row)
    const target = rows[index + direction]
    if (index < 0 || !target) return

    if (direction < 0) this.editorRowsTarget.insertBefore(row, target)
    else this.editorRowsTarget.insertBefore(row, target.nextSibling)

    this.refreshEditorOrderInputs()
    this.syncEditorMoveButtons()
  }

  ensureEditorSearchControl() {
    if (!this.hasEditorRowsTarget || this.editorSearchControl) return

    const wrapper = document.createElement("div")
    wrapper.className = "rails-table-preferences-editor__tools"
    wrapper.dataset.railsTablePreferencesEditorSearch = "true"

    const label = document.createElement("label")
    label.className = "rails-table-preferences-editor__search"
    const labelText = document.createElement("span")
    labelText.textContent = this.editorSearchLabelValue
    const input = document.createElement("input")
    input.type = "search"
    input.placeholder = this.editorSearchPlaceholderValue
    input.setAttribute("aria-label", this.editorSearchLabelValue)
    input.dataset.railsTablePreferencesEditorSearchInput = "true"
    input.addEventListener("input", () => this.syncEditorSearchResults())
    label.append(labelText, input)

    const empty = document.createElement("p")
    empty.className = "rails-table-preferences-editor__search-empty"
    empty.dataset.railsTablePreferencesEditorSearchEmpty = "true"
    empty.hidden = true
    empty.textContent = this.editorNoSearchResultsLabelValue

    wrapper.append(label, empty)
    this.editorRowsTarget.before(wrapper)
  }

  syncEditorSearchResults() {
    if (!this.hasEditorRowsTarget) return
    const query = this.editorSearchInput?.value.trim().toLowerCase() || ""
    let visibleCount = 0

    this.editorRows.forEach((row) => {
      const searchableText = row.dataset.railsTablePreferencesEditorSearchText || row.textContent.toLowerCase()
      const hidden = Boolean(query) && !searchableText.includes(query)
      row.hidden = hidden
      if (!hidden) visibleCount += 1
    })

    if (this.editorSearchEmptyMessage) this.editorSearchEmptyMessage.hidden = !query || visibleCount > 0
    this.syncEditorMoveButtons()
  }

  syncEditorMoveButtons() {
    const rows = this.editorRowsForMovement
    this.editorRows.forEach((row) => {
      const index = rows.indexOf(row)
      row.querySelectorAll("[data-rails-table-preferences-move-direction]").forEach((button) => {
        const direction = button.dataset.railsTablePreferencesMoveDirection
        button.disabled = this.busy || row.hidden || index < 0 || (direction === "up" ? index === 0 : index === rows.length - 1)
      })
    })
  }

  setEditorRowsBusyState(busy) {
    super.setEditorRowsBusyState(busy)
    this.syncEditorMoveButtons()
  }

  get editorRowsForMovement() {
    const visibleRows = this.editorRows.filter((row) => !row.hidden)
    return visibleRows.length > 0 ? visibleRows : this.editorRows
  }

  get editorSearchControl() {
    return this.element.querySelector("[data-rails-table-preferences-editor-search]")
  }

  get editorSearchInput() {
    return this.editorSearchControl?.querySelector("[data-rails-table-preferences-editor-search-input]")
  }

  get editorSearchEmptyMessage() {
    return this.editorSearchControl?.querySelector("[data-rails-table-preferences-editor-search-empty]")
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

  filterOperatorText(operator) {
    const key = String(operator)
    const override = this.filterOperatorLabelsValue?.[key]
    if (override !== undefined && override !== null && String(override).trim() !== "") return String(override)
    return super.filterOperatorText(key)
  }
}
