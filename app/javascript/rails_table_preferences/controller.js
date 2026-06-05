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

  buildDefaultSettings() {
    const settings = super.buildDefaultSettings()
    return { ...settings, columns: settings.columns.map((column) => this.withColumnWidthMetadata(column)) }
  }

  mergeSettings(defaultSettings, savedSettings) {
    const settings = super.mergeSettings(defaultSettings, savedSettings)
    return { ...settings, columns: settings.columns.map((column) => this.withColumnWidthMetadata(column)) }
  }

  settingsFromEditor() {
    if (!this.hasEditorRowsTarget) return this.settingsValue
    const columns = this.editorRows.map((row, index) => {
      const key = row.dataset.railsTablePreferencesColumnKey
      const current = this.columnByKey(key) || {}
      return this.withColumnWidthMetadata({
        key,
        visible: row.querySelector('[data-field="visible"]')?.checked ?? true,
        order: this.integerValue(row.querySelector('[data-field="order"]')?.value) ?? current.order ?? (index + 1) * 10,
        width: this.clampColumnWidth(key, row.querySelector('[data-field="width"]')?.value),
        truncate: this.integerValue(row.querySelector('[data-field="truncate"]')?.value),
        pinned: current.pinned === true
      })
    })
    return { ...this.settingsValue, columns, filters: this.settingsValue?.filters || {}, sorts: this.settingsValue?.sorts || [] }
  }

  syncEditorWidthInputs() {
    if (!this.hasEditorRowsTarget) return
    this.editorRows.forEach((row) => {
      const column = this.columnByKey(row.dataset.railsTablePreferencesColumnKey)
      const widthInput = row.querySelector('[data-field="width"]')
      const width = this.clampColumnWidth(column?.key, column?.width)
      if (widthInput && width) widthInput.value = String(width)
    })
  }

  resizeColumn(event) {
    if (this.busy || !this.resizingColumn) return
    const measuredWidth = Math.round(this.resizingColumn.startWidth + event.clientX - this.resizingColumn.startX)
    const width = this.clampColumnWidth(this.resizingColumn.key, measuredWidth, { min: 40 })
    this.updateColumnSetting(this.resizingColumn.key, { width })
    this.applyColumn(this.columnByKey(this.resizingColumn.key))
    this.syncPinnedColumnOffsets()
    this.syncEditorWidthInputs()
    this.clearSuccessfulStatus()
  }

  autoFitWidthForColumn(key) {
    const cells = Array.from(this.cellsFor(key)).filter((cell) => !cell.hidden && cell.offsetParent !== null)
    if (cells.length === 0) return null
    const measured = Math.max(...cells.map((cell) => this.measureAutoFitCellWidth(cell))) + this.normalizedResizeAutoFitPadding
    return this.clampColumnWidth(key, Math.ceil(measured), {
      min: this.normalizedResizeAutoFitMinWidth,
      max: this.normalizedResizeAutoFitMaxWidth
    })
  }

  applyColumn(column) {
    if (!column) return
    super.applyColumn(this.columnWithClampedWidth(column))
  }

  autoFitColumnFromHandle(event) {
    super.autoFitColumnFromHandle(event)
    this.clearSuccessfulStatus()
  }

  syncPinnedColumnOffsets() {
    let left = 0
    this.orderedColumnsFromSettings.forEach((column) => {
      const cells = Array.from(this.cellsFor(column.key))
      if (column.pinned !== true || column.visible === false) {
        cells.forEach((cell) => cell.style.removeProperty("--rails-table-preferences-pinned-left"))
        return
      }
      cells.forEach((cell) => cell.style.setProperty("--rails-table-preferences-pinned-left", `${left}px`))
      const firstVisibleCell = cells.find((cell) => !cell.hidden)
      left += this.clampColumnWidth(column.key, column.width) || Math.round(firstVisibleCell?.getBoundingClientRect().width || 0)
    })
  }

  columnWithClampedWidth(column) {
    return { ...column, width: this.clampColumnWidth(column.key, column.width) }
  }

  withColumnWidthMetadata(column) {
    const definition = this.columnsValue.find((candidate) => candidate.key === column.key) || {}
    const minWidth = this.positiveIntegerValue(definition.min_width)
    const maxWidth = this.positiveIntegerValue(definition.max_width)
    const attributes = { ...column }

    if (minWidth) attributes.min_width = minWidth
    else delete attributes.min_width

    if (maxWidth) attributes.max_width = maxWidth
    else delete attributes.max_width

    return attributes
  }

  columnWidthBounds(key, fallbacks = {}) {
    const definition = this.columnsValue.find((column) => column.key === key) || {}
    return {
      min: this.positiveIntegerValue(definition.min_width) ?? this.positiveIntegerValue(fallbacks.min),
      max: this.positiveIntegerValue(definition.max_width) ?? this.positiveIntegerValue(fallbacks.max)
    }
  }

  clampColumnWidth(key, width, fallbacks = {}) {
    const value = this.positiveIntegerValue(width)
    if (value === null) return null

    const { min, max } = this.columnWidthBounds(key, fallbacks)
    if (min !== null && max !== null && min > max) return min

    let clamped = value
    if (min !== null) clamped = Math.max(min, clamped)
    if (max !== null) clamped = Math.min(max, clamped)
    return clamped
  }

  positiveIntegerValue(value) {
    const integer = this.integerValue(value)
    return integer !== null && integer > 0 ? integer : null
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
