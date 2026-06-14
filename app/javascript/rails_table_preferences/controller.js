import RailsTablePreferencesBaseController from "../controllers/rails_table_preferences_controller"

const DATE_TIME_FILTER_TYPES = new Set(["datetime", "datetime-local", "time"])

export default class RailsTablePreferencesController extends RailsTablePreferencesBaseController {
  static values = {
    ...RailsTablePreferencesBaseController.values,
    editorIdPrefix: String,
    filterOperatorLabels: { type: Object, default: {} },
    selectFilterOptionSearchLabel: { type: String, default: "候補を絞り込み" },
    selectFilterOptionSearchPlaceholder: { type: String, default: "候補を絞り込み" },
    editorSearchLabel: { type: String, default: "列を検索" },
    editorSearchPlaceholder: { type: String, default: "列名で絞り込み" },
    editorNoSearchResultsLabel: { type: String, default: "一致する列はありません。検索語を変更してください。" },
    visibilityBulkHiddenStatusLabel: { type: String, default: "すべての列を非表示にしました。全列表示で戻せます。" },
    visibilityBulkShownStatusLabel: { type: String, default: "すべての列を表示しました。" },
    moveUpLabel: { type: String, default: "上へ移動" },
    moveDownLabel: { type: String, default: "下へ移動" },
    resizeAutoFitStatusLabel: { type: String, default: "列幅を自動調整しました。" },
    selectFilterOptionSearchThreshold: { type: Number, default: 8 }
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

  settingsFromEditor() {
    const editorSettings = super.settingsFromEditor()
    return this.defaultSettings ? this.mergeSettings(this.defaultSettings, editorSettings) : editorSettings
  }

  filterPanelId(columnKey) {
    const namespace = this.filterPanelIdNamespace
    const normalizedColumnKey = String(columnKey || "column").replace(/[^a-zA-Z0-9_-]+/g, "-")
    return `rails-table-preferences-filter-panel-${namespace}-${normalizedColumnKey}`
  }

  get filterPanelIdNamespace() {
    const namespace = this.editorIdPrefixValue || this.tableKeyValue || "table"
    return String(namespace).replace(/[^a-zA-Z0-9_-]+/g, "-")
  }

  filterPlaceholderAttribute(value) {
    const text = String(value ?? "").trim()
    if (!text) return ""
    return ` placeholder="${this.escapeHtml(text)}"`
  }

  filterInputAffordanceAttributes(filter, placeholder) {
    const attributes = [this.filterPlaceholderAttribute(placeholder)]
    if (["number", "date"].includes(this.filterInputType(filter))) {
      attributes.push(this.filterInputAttribute("min", filter.min))
      attributes.push(this.filterInputAttribute("max", filter.max))
      attributes.push(this.filterInputAttribute("step", filter.step))
    }
    return attributes.join("")
  }

  filterInputAttribute(name, value) {
    const text = String(value ?? "").trim()
    if (!text) return ""
    return ` ${name}="${this.escapeHtml(text)}"`
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
    if (!wasBusy) {
      this.clearEditorSearchQuery()
      this.clearSuccessfulStatus()
      this.dispatchPreferenceEvent("applied", { action: "reset" })
    }
    return result
  }

  renderEditor() {
    super.renderEditor()
    this.ensureEditorSearchControl()
    this.syncEditorSearchResults()
    this.syncEditorMoveButtons()
  }

  buildEditorRow(column) {
    const row = super.buildEditorRow(column)
    this.replaceEditorDragHandle(row)
    row.addEventListener("input", () => this.clearSuccessfulStatus())
    row.addEventListener("change", () => this.clearSuccessfulStatus())
    row.dataset.railsTablePreferencesEditorSearchText = this.editorSearchTextForColumn(column)
    row.insertBefore(this.buildEditorMoveControls(), row.querySelector(".rails-table-preferences-editor__visible"))
    return row
  }

  editorSearchTextForColumn(column) {
    return [
      column.label,
      column.key,
      ...this.editorSearchGroupTokens(column.group)
    ].filter(Boolean).map((token) => String(token).toLowerCase()).join(" ")
  }

  editorSearchGroupTokens(group) {
    if (!group) return []
    if (Array.isArray(group)) return group.flatMap((item) => this.editorSearchGroupTokens(item))
    if (typeof group === "object") return [group.key, group.label].filter(Boolean)
    return [group]
  }

  replaceEditorDragHandle(row) {
    const handle = row.querySelector(".rails-table-preferences-editor__drag-handle")
    if (!handle) return

    const visualHandle = document.createElement("span")
    visualHandle.className = handle.className
    visualHandle.dataset.railsTablePreferencesEditorDragHandle = "visual"
    visualHandle.draggable = false
    visualHandle.setAttribute("aria-hidden", "true")
    visualHandle.textContent = handle.textContent || "↕"
    handle.replaceWith(visualHandle)
  }

  showAllEditorColumns(event) {
    this.setEditorColumnVisibility(event, true)
  }

  hideAllEditorColumns(event) {
    this.setEditorColumnVisibility(event, false)
  }

  setEditorColumnVisibility(event, visible) {
    if (this.busy) return
    if (event) event.preventDefault()
    this.editorRows.forEach((row) => {
      const visibleInput = row.querySelector('[data-field="visible"]')
      if (visibleInput) visibleInput.checked = visible === true
    })
    this.setStatus(visible ? this.visibilityBulkShownStatusLabelValue : this.visibilityBulkHiddenStatusLabelValue, "success")
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
    empty.setAttribute("role", "status")
    empty.setAttribute("aria-live", "polite")
    empty.setAttribute("aria-atomic", "true")
    empty.hidden = true
    empty.textContent = this.editorNoSearchResultsLabelValue

    wrapper.append(label, empty)
    this.editorRowsTarget.before(wrapper)
  }

  clearEditorSearchQuery() {
    const input = this.editorSearchInput
    if (input) input.value = ""
    this.syncEditorSearchResults()
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

  dragEditorRowOver(event) {
    super.dragEditorRowOver(event)
    this.clearSuccessfulStatus()
  }

  dropEditorRow(event) {
    super.dropEditorRow(event)
    this.clearSuccessfulStatus()
    this.syncEditorMoveButtons()
  }

  dragEditorRowEnd(event) {
    super.dragEditorRowEnd(event)
    this.clearSuccessfulStatus()
    this.syncEditorMoveButtons()
  }

  resizeColumn(event) {
    super.resizeColumn(event)
    this.clearSuccessfulStatus()
  }

  autoFitColumnFromHandle(event) {
    const wasBusy = this.busy
    const result = super.autoFitColumnFromHandle(event)
    if (!wasBusy) this.setStatus(this.resizeAutoFitStatusLabelValue, "success")
    return result
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
    this.syncEditorMoveButtons()
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
    const nextState = message ? state : "idle"
    this.statusState = nextState
    this.syncStatusStateHook(nextState)
    super.setStatus(message)
  }

  syncStatusStateHook(state = this.statusState || "idle") {
    const target = this.hasStatusTarget ? this.statusTarget : null
    if (!target || typeof target.setAttribute !== "function") return
    target.setAttribute("data-rails-table-preferences-status-state", state || "idle")
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
    if (result !== null && this.statusState === "success") {
      this.clearEditorSearchQuery()
      this.dispatchPreferenceEvent("loaded", { action: "load" })
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
        this.clearEditorSearchQuery()
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
    this.syncStatusStateHook("error")
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

  installTableColumnDragHandles() {
    this.headerCells.forEach((cell) => {
      if (cell.dataset.railsTablePreferencesTableDragInstalled === "true") return
      if (!this.tableColumnDraggable(cell)) {
        cell.draggable = false
        cell.dataset.railsTablePreferencesTableDragDisabled = "true"
        return
      }

      cell.draggable = true
      cell.dataset.railsTablePreferencesTableDragInstalled = "true"
      cell.classList.add("rails-table-preferences-table-column-draggable")
      cell.addEventListener("dragstart", this.startTableColumnDrag.bind(this))
      cell.addEventListener("dragover", this.dragTableColumnOver.bind(this))
      cell.addEventListener("drop", this.dropTableColumn.bind(this))
      cell.addEventListener("dragend", this.endTableColumnDrag.bind(this))
    })
  }

  startTableColumnDrag(event) {
    if (!this.tableColumnDraggable(event.currentTarget)) {
      event.preventDefault()
      return
    }

    super.startTableColumnDrag(event)
  }

  tableColumnDraggable(cell) {
    const key = cell?.dataset?.railsTablePreferencesColumnKey
    return this.columnDefinitionByKey(key)?.draggable !== false
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

  showAllColumns(event) {
    if (this.busy) return
    if (event) event.preventDefault()

    this.settingsValue = {
      ...this.settingsValue,
      columns: this.columnsFromSettings.map((column) => ({ ...column, visible: true })),
      filters: this.settingsValue?.filters || {},
      sorts: this.settingsValue?.sorts || []
    }
    this.closeFilterPanel()
    this.renderEditor()
    this.apply()
  }

  clearFiltersAndSorts(event) {
    if (this.busy) return
    if (event) event.preventDefault()
    this.settingsValue = { ...this.settingsValue, filters: {}, sorts: [] }
    this.closeFilterPanel()
    this.apply()
    this.dispatchPreferenceEvent("applied", { action: "clear-filters-and-sorts" })
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

    if (["text", "number", "date"].includes(this.filterInputType(filter))) {
      if (["blank", "present", "true", "false"].includes(selectedOperator)) return ""
      if (selectedOperator === "between") {
        const inputType = this.filterInputType(filter)
        const fromAttributes = this.filterInputAffordanceAttributes(filter, filter.from_placeholder)
        const toAttributes = this.filterInputAffordanceAttributes(filter, filter.to_placeholder)
        return `
          <label class="rails-table-preferences-filter-panel__field">${this.escapeHtml(this.filterFromLabelValue)}<input type="${inputType}" data-field="from" value="${this.escapeHtml(condition.from ?? "")}"${fromAttributes}></label>
          <label class="rails-table-preferences-filter-panel__field">${this.escapeHtml(this.filterToLabelValue)}<input type="${inputType}" data-field="to" value="${this.escapeHtml(condition.to ?? "")}"${toAttributes}></label>
        `
      }

      const attributes = this.filterInputAffordanceAttributes(filter, filter.placeholder)
      return `<label class="rails-table-preferences-filter-panel__field">${this.escapeHtml(this.filterValueLabelValue)}<input type="${this.filterInputType(filter)}" data-field="value" value="${this.escapeHtml(condition.value ?? "")}"${attributes}></label>`
    }

    return super.filterValueHtml(filter, condition, selectedOperator)
  }

  selectFilterOptionSearchHtml(options) {
    if (!Array.isArray(options) || options.length === 0 || options.length < this.selectFilterOptionSearchThreshold) return ""

    const searchLabel = this.selectFilterOptionSearchLabelValue || "候補を絞り込み"
    const searchPlaceholder = this.selectFilterOptionSearchPlaceholderValue || "候補を絞り込み"
    const label = `${this.filterValueLabelValue}: ${searchLabel}`
    const emptyLabel = "一致する候補はありません。選択済みの候補は表示したままです。"
    return `<input type="search" class="rails-table-preferences-filter-panel__option-search" data-field="option-search" aria-label="${this.escapeHtml(label)}" placeholder="${this.escapeHtml(searchPlaceholder)}"><p class="rails-table-preferences-filter-panel__option-search-empty" data-rails-table-preferences-option-search-empty role="status" aria-live="polite" aria-atomic="true" hidden>${this.escapeHtml(emptyLabel)}</p>`
  }

  installSelectFilterOptionSearch(panel) {
    const input = panel?.querySelector("[data-field='option-search']")
    const select = panel?.querySelector("[data-field='values']")
    const emptyMessage = panel?.querySelector("[data-rails-table-preferences-option-search-empty]")
    if (!input || !select || input.dataset.railsTablePreferencesOptionSearchInstalled === "true") return

    input.dataset.railsTablePreferencesOptionSearchInstalled = "true"
    input.addEventListener("input", () => this.filterSelectOptionsBySearch(input, select, emptyMessage))
    select.addEventListener("change", () => this.filterSelectOptionsBySearch(input, select, emptyMessage))
    this.filterSelectOptionsBySearch(input, select, emptyMessage)
  }

  filterSelectOptionsBySearch(input, select, emptyMessage = null) {
    const query = String(input?.value || "").trim().toLocaleLowerCase()
    let matchingOptions = 0

    Array.from(select?.options || []).forEach((option) => {
      const searchableText = `${option.textContent || ""} ${option.value || ""}`.toLocaleLowerCase()
      const matchesQuery = searchableText.includes(query)
      if (matchesQuery) matchingOptions += 1
      option.hidden = Boolean(query) && !option.selected && !matchesQuery
    })

    if (emptyMessage) emptyMessage.hidden = !query || matchingOptions > 0
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

  get selectFilterOptionSearchThreshold() {
    const rawValue = this.element?.dataset?.railsTablePreferencesSelectFilterOptionSearchThresholdValue
    if (rawValue !== undefined && String(rawValue).trim() === "") return 8

    const threshold = Number(this.selectFilterOptionSearchThresholdValue)
    if (!Number.isFinite(threshold)) return 8
    return Math.floor(threshold)
  }

  filterOperatorsFor(filter) {
    if (Array.isArray(filter.operators) && filter.operators.length > 0) return filter.operators.map(String)
    if (DATE_TIME_FILTER_TYPES.has(String(filter.type))) return ["equals", "gteq", "lteq", "between", "blank", "present"]
    return super.filterOperatorsFor(filter)
  }

  filterInputType(filter) {
    const type = String(filter.type)
    if (type === "datetime" || type === "datetime-local") return "datetime-local"
    if (type === "time") return "time"
    return super.filterInputType(filter)
  }

  filterOperatorText(operator) {
    const key = String(operator)
    const override = this.filterOperatorLabelsValue?.[key]
    if (override !== undefined && override !== null && String(override).trim() !== "") return String(override)
    return super.filterOperatorText(key)
  }
}
