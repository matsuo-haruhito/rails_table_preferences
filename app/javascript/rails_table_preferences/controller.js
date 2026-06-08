import RailsTablePreferencesBaseController from "../controllers/rails_table_preferences_controller"

export default class RailsTablePreferencesController extends RailsTablePreferencesBaseController {
  static values = {
    ...RailsTablePreferencesBaseController.values,
    filterOperatorLabels: { type: Object, default: {} },
    editorSearchLabel: { type: String, default: "列を検索" },
    editorSearchPlaceholder: { type: String, default: "列名で絞り込み" },
    editorNoSearchResultsLabel: { type: String, default: "一致する列はありません。検索語を変更してください。" },
    moveUpLabel: { type: String, default: "上へ移動" },
    moveDownLabel: { type: String, default: "下へ移動" },
    resetStatusLabel: { type: String, default: "テーブル初期設定に戻しました。" }
  }

  buildPresetOption(preset) {
    const option = super.buildPresetOption(preset)
    const name = preset.name || "default"
    const scopeType = preset.scope_type || "owner"
    const scopeLabel = preset.scope_label || this.scopeFallbackLabel(scopeType)
    const defaultMark = preset.default === true ? " *" : ""
    const scopeMark = scopeLabel ? ` [${scopeLabel}]` : ""
    option.textContent = `${name}${scopeMark}${defaultMark}`
    return option
  }

  filterPlaceholderAttribute(value) {
    const text = String(value ?? "").trim()
    if (!text) return ""
    return ` placeholder="${this.escapeHtml(text)}"`
  }

  connect() {
    this.statusState = "idle"
    super.connect()
    this.syncResetButtonState()
  }

  applyFromEditor(event) {
    const wasBusy = this.busy
    const result = super.applyFromEditor(event)
    if (!wasBusy) {
      this.clearSuccessfulStatus()
      this.syncResetButtonState()
      this.dispatchPreferenceEvent("applied", { action: "apply" })
    }
    return result
  }

  resetEditor(event) {
    const wasBusy = this.busy
    const result = super.resetEditor(event)
    if (!wasBusy) {
      this.setStatus(this.resetStatusLabelValue, "success")
      this.syncResetButtonState()
    }
    return result
  }

  renderEditor() {
    super.renderEditor()
    this.ensureEditorSearchControl()
    this.syncEditorSearchResults()
    this.syncEditorMoveButtons()
    this.syncResetButtonState()
  }

  buildEditorRow(column) {
    const row = super.buildEditorRow(column)
    const syncEditorDraftState = () => {
      this.clearSuccessfulStatus()
      this.syncResetButtonState()
    }
    row.addEventListener("input", syncEditorDraftState)
    row.addEventListener("change", syncEditorDraftState)
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
    this.clearSuccessfulStatus()
    this.syncResetButtonState()
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
    this.syncResetButtonState()
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
    this.syncResetButtonState()
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

  dragEditorRowOver(event) {
    super.dragEditorRowOver(event)
    this.clearSuccessfulStatus()
    this.syncResetButtonState()
  }

  dropEditorRow(event) {
    super.dropEditorRow(event)
    this.clearSuccessfulStatus()
    this.syncEditorMoveButtons()
    this.syncResetButtonState()
  }

  dragEditorRowEnd(event) {
    super.dragEditorRowEnd(event)
    this.clearSuccessfulStatus()
    this.syncEditorMoveButtons()
    this.syncResetButtonState()
  }

  resizeColumn(event) {
    super.resizeColumn(event)
    this.clearSuccessfulStatus()
    this.syncResetButtonState()
  }

  autoFitColumnFromHandle(event) {
    super.autoFitColumnFromHandle(event)
    this.clearSuccessfulStatus()
    this.syncResetButtonState()
  }

  dragTableColumnOver(event) {
    super.dragTableColumnOver(event)
    this.clearSuccessfulStatus()
    this.syncResetButtonState()
  }

  dropTableColumn(event) {
    super.dropTableColumn(event)
    this.clearSuccessfulStatus()
    this.syncResetButtonState()
  }

  endTableColumnDrag(event) {
    super.endTableColumnDrag(event)
    this.clearSuccessfulStatus()
    this.syncResetButtonState()
  }

  toggleSortFromHeader(event, cell, column) {
    super.toggleSortFromHeader(event, cell, column)
    this.clearSuccessfulStatus()
    this.syncResetButtonState()
  }

  applyFilterPanel(key, panel) {
    super.applyFilterPanel(key, panel)
    this.clearSuccessfulStatus()
    this.syncResetButtonState()
  }

  clearFilter(key) {
    super.clearFilter(key)
    this.clearSuccessfulStatus()
    this.syncResetButtonState()
  }

  setStatus(message, state = "idle") {
    this.statusState = message ? state : "idle"
    super.setStatus(message)
  }

  clearSuccessfulStatus() {
    if (this.statusState === "success") this.setStatus("")
  }

  syncResetButtonState() {
    const button = this.resetEditorButton
    if (!button) return
    button.disabled = this.busy || this.editorMatchesDefaultSettings()
  }

  editorMatchesDefaultSettings() {
    try {
      return this.normalizedSettingsFingerprint(this.settingsFromEditor()) === this.normalizedSettingsFingerprint(this.defaultSettings)
    } catch (_error) {
      return false
    }
  }

  normalizedSettingsFingerprint(settings = {}) {
    const columns = Array.isArray(settings.columns) ? settings.columns.map((column) => ({
      key: String(column.key || ""),
      visible: column.visible === false ? false : true,
      order: Number.isFinite(Number(column.order)) ? Number(column.order) : null,
      width: Number.isFinite(Number(column.width)) ? Number(column.width) : null,
      truncate: Number.isFinite(Number(column.truncate)) ? Number(column.truncate) : null,
      pinned: column.pinned === true
    })) : []

    return JSON.stringify({
      columns,
      filters: settings.filters || {},
      sorts: Array.isArray(settings.sorts) ? settings.sorts : []
    })
  }

  get resetEditorButton() {
    return this.element?.querySelector("[data-action~='rails-table-preferences#resetEditor']")
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
      this.syncResetButtonState()
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
    this.syncResetButtonState()
  }

  openFilterPanel(headerCell, column, button = headerCell.querySelector("[data-rails-table-preferences-filter-button]")) {
    super.openFilterPanel(headerCell, column, button)
    if (!this.filterPanel) return

    this.filterPanel.setAttribute("role", "group")
    this.filterPanel.setAttribute("aria-labelledby", this.filterPanelTitleId(column.key))
    this.installSelectFilterOptionSearch(this.filterPanel)
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

  renderFilterPanelValueFields(panel, column) {
    super.renderFilterPanelValueFields(panel, column)
    this.installSelectFilterOptionSearch(panel)
  }

  filterValueHtml(filter, condition, selectedOperator) {
    if (filter.type === "select" && Array.isArray(filter.options) && !["blank", "present", "true", "false"].includes(selectedOperator)) {
      const values = new Set(Array(condition.values || condition.value || []).map(String))
      const optionsHtml = filter.options.map((option) => {
        const value = this.selectFilterOptionValue(option)
        const label = this.selectFilterOptionLabel(option, value)
        return `<option value="${this.escapeHtml(value)}" ${values.has(String(value)) ? "selected" : ""}>${this.escapeHtml(label)}</option>`
      }).join("")
      return `<label class="rails-table-preferences-filter-panel__field">${this.escapeHtml(this.filterValueLabelValue)}${this.selectFilterOptionSearchHtml(filter.options)}<select data-field="values" multiple>${optionsHtml}</select></label>`
    }

    return super.filterValueHtml(filter, condition, selectedOperator)
  }

  selectFilterOptionSearchHtml(options) {
    if (!Array.isArray(options) || options.length < this.selectFilterOptionSearchThreshold) return ""

    const label = `${this.filterValueLabelValue}: 候補を絞り込み`
    return `<input type="search" class="rails-table-preferences-filter-panel__option-search" data-field="option-search" aria-label="${this.escapeHtml(label)}" placeholder="${this.escapeHtml("候補を絞り込み")}">`
  }

  installSelectFilterOptionSearch(panel) {
    const input = panel?.querySelector("[data-field='option-search']")
    const select = panel?.querySelector("[data-field='values']")
    if (!input || !select || input.dataset.railsTablePreferencesOptionSearchInstalled === "true") return

    input.dataset.railsTablePreferencesOptionSearchInstalled = "true"
    input.addEventListener("input", () => this.filterSelectOptionsBySearch(input, select))
    select.addEventListener("change", () => this.filterSelectOptionsBySearch(input, select))
    this.filterSelectOptionsBySearch(input, select)
  }

  filterSelectOptionsBySearch(input, select) {
    const query = String(input?.value || "").trim().toLocaleLowerCase()
    Array.from(select?.options || []).forEach((option) => {
      const searchableText = `${option.textContent || ""} ${option.value || ""}`.toLocaleLowerCase()
      option.hidden = Boolean(query) && !option.selected && !searchableText.includes(query)
    })
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

  get selectFilterOptionSearchThreshold() { return 8 }

  filterOperatorText(operator) {
    const key = String(operator)
    const override = this.filterOperatorLabelsValue?.[key]
    if (override !== undefined && override !== null && String(override).trim() !== "") return String(override)
    return super.filterOperatorText(key)
  }
}
