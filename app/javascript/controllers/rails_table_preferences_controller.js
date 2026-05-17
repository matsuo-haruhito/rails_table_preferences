import { Controller } from "@hotwired/stimulus"

// Applies and edits saved table display preferences for a server-rendered table.
//
// Expected table markup:
//   <table data-controller="rails-table-preferences" ...>
//     <th data-rails-table-preferences-column-key="customer_code">...</th>
//     <td data-rails-table-preferences-column-key="customer_code">...</td>
//   </table>
//
// The same controller can also be used with the editor helper.
export default class extends Controller {
  static targets = ["editorRows", "presetName", "presetSelect", "defaultPreset"]

  static values = {
    tableKey: String,
    name: { type: String, default: "default" },
    url: String,
    collectionUrl: String,
    settings: Object,
    columns: Array,
    resizeHandleWidth: { type: Number, default: 10 },
    reorderSensitivity: { type: Number, default: 1.2 },
    orderLabel: { type: String, default: "表示順" },
    widthLabel: { type: String, default: "列幅" },
    truncateLabel: { type: String, default: "省略文字数" },
    dragLabel: { type: String, default: "ドラッグして並び替え" },
    resizeLabel: { type: String, default: "列幅を変更" },
    filterLabel: { type: String, default: "絞り込み" },
    filterApplyLabel: { type: String, default: "適用" },
    filterClearLabel: { type: String, default: "クリア" },
    filterOperatorLabel: { type: String, default: "条件" },
    filterValueLabel: { type: String, default: "値" },
    filterFromLabel: { type: String, default: "開始" },
    filterToLabel: { type: String, default: "終了" }
  }

  connect() {
    this.draggedEditorRow = null
    this.draggedTableColumnKey = null
    this.resizingColumn = null
    this.filterPanel = null
    this.presets = []
    this.defaultSettings = this.buildDefaultSettings()
    this.settingsValue = this.mergeSettings(this.defaultSettings, this.settingsValue || {})
    this.renderEditor()
    this.apply()
    this.installResizeHandles()
    this.installTableColumnDragHandles()
    this.installFilterControls()
    this.refreshPresetOptions()
  }

  disconnect() {
    this.uninstallDocumentResizeListeners()
    this.closeFilterPanel()
  }

  apply() {
    this.applyColumnOrder()
    this.columnsFromSettings.forEach((column) => {
      this.applyColumn(column)
    })
    this.syncEditorWidthInputs()
    this.syncFilterButtonStates()
  }

  applyFromEditor(event) {
    if (event) event.preventDefault()

    this.settingsValue = this.settingsFromEditor()
    this.apply()
  }

  async saveFromEditor(event) {
    if (event) event.preventDefault()

    this.settingsValue = this.settingsFromEditor()
    await this.save()
  }

  async createPresetFromEditor(event) {
    if (event) event.preventDefault()

    this.settingsValue = this.settingsFromEditor()
    const response = await fetch(this.collectionUrlValue, {
      method: "POST",
      headers: this.jsonHeaders,
      body: JSON.stringify({ name: this.currentPresetName, settings: this.settingsValue, default: this.defaultPresetChecked })
    })

    if (!response.ok) {
      throw new Error(`Failed to create table preference preset: ${response.status}`)
    }

    const payload = await response.json()
    this.nameValue = payload.name
    this.urlValue = this.preferenceUrl(payload.name)
    this.setPresetNameInput(payload.name)
    this.setDefaultPresetInput(payload.default)
    this.settingsValue = this.mergeSettings(this.defaultSettings, payload.settings)
    this.renderEditor()
    this.apply()
    await this.refreshPresetOptions()
  }

  async deletePreset(event) {
    if (event) event.preventDefault()

    const response = await fetch(this.preferenceUrl(this.currentPresetName), {
      method: "DELETE",
      headers: {
        "Accept": "application/json",
        "X-CSRF-Token": this.csrfToken
      }
    })

    if (!response.ok && response.status !== 204) {
      throw new Error(`Failed to delete table preference preset: ${response.status}`)
    }

    this.nameValue = "default"
    this.urlValue = this.preferenceUrl("default")
    this.setPresetNameInput("default")
    this.setDefaultPresetInput(false)
    this.settingsValue = this.defaultSettings
    this.renderEditor()
    this.apply()
    await this.refreshPresetOptions()
  }

  async save(event) {
    if (event) event.preventDefault()

    const response = await fetch(this.preferenceUrl(this.currentPresetName), {
      method: "PATCH",
      headers: this.jsonHeaders,
      body: JSON.stringify({ settings: this.settingsValue, default: this.defaultPresetChecked })
    })

    if (!response.ok) {
      throw new Error(`Failed to save table preferences: ${response.status}`)
    }

    const payload = await response.json()
    this.nameValue = payload.name
    this.urlValue = this.preferenceUrl(payload.name)
    this.setPresetNameInput(payload.name)
    this.setDefaultPresetInput(payload.default)
    this.settingsValue = this.mergeSettings(this.defaultSettings, payload.settings)
    this.renderEditor()
    this.apply()
    await this.refreshPresetOptions()
  }

  resetEditor(event) {
    if (event) event.preventDefault()

    this.settingsValue = this.defaultSettings
    this.closeFilterPanel()
    this.renderEditor()
    this.apply()
  }

  async loadPresets() {
    const response = await fetch(this.collectionUrlValue, { headers: { "Accept": "application/json" } })

    if (!response.ok) {
      throw new Error(`Failed to load table preference presets: ${response.status}`)
    }

    return response.json()
  }

  async refreshPresetOptions() {
    if (!this.hasPresetSelectTarget) return

    const payload = await this.loadPresets()
    this.presets = payload.preferences || []
    this.renderPresetOptions()
  }

  renderPresetOptions() {
    if (!this.hasPresetSelectTarget) return

    this.presetSelectTarget.innerHTML = ""

    if (this.presets.length === 0) {
      this.presetSelectTarget.appendChild(this.buildPresetOption(this.currentPresetName, false))
    } else {
      this.presets.forEach((preset) => {
        this.presetSelectTarget.appendChild(this.buildPresetOption(preset.name, preset.default === true))
      })
    }

    this.presetSelectTarget.value = this.currentPresetName
  }

  buildPresetOption(name, defaultFlag) {
    const option = document.createElement("option")
    option.value = name
    option.textContent = defaultFlag ? `${name} *` : name
    option.dataset.default = defaultFlag ? "true" : "false"
    return option
  }

  async selectPreset(event) {
    if (event) event.preventDefault()

    const name = this.presetSelectTarget.value || "default"
    const response = await fetch(this.preferenceUrl(name), { headers: { "Accept": "application/json" } })

    if (!response.ok) {
      throw new Error(`Failed to load table preference preset: ${response.status}`)
    }

    const payload = await response.json()
    this.nameValue = payload.name
    this.urlValue = this.preferenceUrl(payload.name)
    this.setPresetNameInput(payload.name)
    this.setDefaultPresetInput(payload.default)
    this.settingsValue = this.mergeSettings(this.defaultSettings, payload.settings)
    this.closeFilterPanel()
    this.renderEditor()
    this.apply()
  }

  renderEditor() {
    if (!this.hasEditorRowsTarget) return

    this.editorRowsTarget.innerHTML = ""

    this.columnsFromSettings.forEach((column) => {
      this.editorRowsTarget.appendChild(this.buildEditorRow(column))
    })

    this.refreshEditorOrderInputs()
  }

  buildEditorRow(column) {
    const row = document.createElement("div")
    row.className = "rails-table-preferences-editor__row"
    row.draggable = true
    row.dataset.railsTablePreferencesColumnKey = column.key
    row.addEventListener("dragstart", this.dragEditorRowStart.bind(this))
    row.addEventListener("dragover", this.dragEditorRowOver.bind(this))
    row.addEventListener("drop", this.dropEditorRow.bind(this))
    row.addEventListener("dragend", this.dragEditorRowEnd.bind(this))

    row.innerHTML = `
      <button type="button" class="rails-table-preferences-editor__drag-handle" draggable="false" aria-label="${this.escapeHtml(this.dragLabelValue)}" title="${this.escapeHtml(this.dragLabelValue)}">↕</button>
      <label class="rails-table-preferences-editor__visible">
        <input type="checkbox" data-field="visible" ${column.visible === false ? "" : "checked"}>
        <span>${this.escapeHtml(column.label || column.key)}</span>
      </label>
      <label>
        ${this.escapeHtml(this.orderLabelValue)}
        <input type="number" data-field="order" value="${column.order ?? ""}" inputmode="numeric">
      </label>
      <label>
        ${this.escapeHtml(this.widthLabelValue)}
        <input type="number" data-field="width" value="${column.width ?? ""}" inputmode="numeric">
      </label>
      <label>
        ${this.escapeHtml(this.truncateLabelValue)}
        <input type="number" data-field="truncate" value="${column.truncate ?? ""}" inputmode="numeric">
      </label>
    `

    return row
  }

  dragEditorRowStart(event) {
    const row = event.currentTarget
    this.draggedEditorRow = row
    row.classList.add("rails-table-preferences-editor__row--dragging")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", row.dataset.railsTablePreferencesColumnKey)
  }

  dragEditorRowOver(event) {
    event.preventDefault()

    const targetRow = event.currentTarget
    if (!this.draggedEditorRow || targetRow === this.draggedEditorRow) return

    const placement = this.editorRowPlacement(event, targetRow)

    if (placement === "before") {
      this.editorRowsTarget.insertBefore(this.draggedEditorRow, targetRow)
    } else {
      this.editorRowsTarget.insertBefore(this.draggedEditorRow, targetRow.nextSibling)
    }

    this.refreshEditorOrderInputs()
  }

  dropEditorRow(event) {
    event.preventDefault()
    this.refreshEditorOrderInputs()
  }

  dragEditorRowEnd(event) {
    event.currentTarget.classList.remove("rails-table-preferences-editor__row--dragging")
    this.draggedEditorRow = null
    this.refreshEditorOrderInputs()
  }

  editorRowPlacement(event, row) {
    const rect = row.getBoundingClientRect()
    const offset = event.clientY - rect.top
    const rows = this.editorRows
    const draggedIndex = rows.indexOf(this.draggedEditorRow)
    const targetIndex = rows.indexOf(row)

    if (draggedIndex >= 0 && targetIndex >= 0) {
      if (draggedIndex < targetIndex) {
        return offset > rect.height * this.reorderActivationRatio ? "after" : "before"
      }

      if (draggedIndex > targetIndex) {
        return offset < rect.height * (1 - this.reorderActivationRatio) ? "before" : "after"
      }
    }

    return offset < rect.height / 2 ? "before" : "after"
  }

  refreshEditorOrderInputs() {
    if (!this.hasEditorRowsTarget) return

    this.editorRows.forEach((row, index) => {
      const orderInput = row.querySelector('[data-field="order"]')
      if (orderInput) orderInput.value = String((index + 1) * 10)
    })
  }

  syncEditorWidthInputs() {
    if (!this.hasEditorRowsTarget) return

    this.editorRows.forEach((row) => {
      const key = row.dataset.railsTablePreferencesColumnKey
      const column = this.columnByKey(key)
      const widthInput = row.querySelector('[data-field="width"]')
      if (widthInput && column?.width) widthInput.value = String(column.width)
    })
  }

  installResizeHandles() {
    this.headerCells.forEach((cell) => {
      if (cell.querySelector("[data-rails-table-preferences-resize-handle]")) return

      const handle = document.createElement("button")
      handle.type = "button"
      handle.className = "rails-table-preferences-resize-handle"
      handle.dataset.railsTablePreferencesResizeHandle = "true"
      handle.setAttribute("aria-label", `${this.resizeLabelValue}: ${cell.dataset.railsTablePreferencesColumnKey}`)
      handle.addEventListener("mousedown", this.startColumnResize.bind(this))
      handle.addEventListener("click", (event) => event.preventDefault())

      this.applyResizeHandleHitArea(cell, handle)
      cell.appendChild(handle)
    })
  }

  applyResizeHandleHitArea(cell, handle) {
    const existingPosition = window.getComputedStyle(cell).position
    if (existingPosition === "static") cell.style.position = "relative"

    handle.style.position = "absolute"
    handle.style.top = "0"
    handle.style.right = "0"
    handle.style.bottom = "0"
    handle.style.width = `${this.normalizedResizeHandleWidth}px`
    handle.style.padding = "0"
    handle.style.border = "0"
    handle.style.background = "transparent"
    handle.style.cursor = "col-resize"
    handle.style.opacity = "0"
    handle.style.zIndex = "1"
  }

  startColumnResize(event) {
    event.preventDefault()
    event.stopPropagation()

    const headerCell = event.currentTarget.closest("[data-rails-table-preferences-column-key]")
    if (!headerCell) return

    const key = headerCell.dataset.railsTablePreferencesColumnKey
    const currentWidth = headerCell.getBoundingClientRect().width

    this.resizingColumn = {
      key,
      startX: event.clientX,
      startWidth: currentWidth
    }

    this.boundResizeColumn = this.resizeColumn.bind(this)
    this.boundStopColumnResize = this.stopColumnResize.bind(this)
    document.addEventListener("mousemove", this.boundResizeColumn)
    document.addEventListener("mouseup", this.boundStopColumnResize)
  }

  resizeColumn(event) {
    if (!this.resizingColumn) return

    const width = Math.max(40, Math.round(this.resizingColumn.startWidth + event.clientX - this.resizingColumn.startX))
    this.updateColumnSetting(this.resizingColumn.key, { width })
    this.applyColumn(this.columnByKey(this.resizingColumn.key))
    this.syncEditorWidthInputs()
  }

  stopColumnResize() {
    this.uninstallDocumentResizeListeners()
    this.resizingColumn = null
  }

  uninstallDocumentResizeListeners() {
    if (this.boundResizeColumn) {
      document.removeEventListener("mousemove", this.boundResizeColumn)
      this.boundResizeColumn = null
    }

    if (this.boundStopColumnResize) {
      document.removeEventListener("mouseup", this.boundStopColumnResize)
      this.boundStopColumnResize = null
    }
  }

  installTableColumnDragHandles() {
    this.headerCells.forEach((cell) => {
      if (cell.dataset.railsTablePreferencesTableDragInstalled === "true") return

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
    if (event.target.closest("[data-rails-table-preferences-resize-handle]") || event.target.closest("[data-rails-table-preferences-filter-button]")) {
      event.preventDefault()
      return
    }

    const cell = event.currentTarget
    const key = cell.dataset.railsTablePreferencesColumnKey
    if (!key) return

    this.draggedTableColumnKey = key
    cell.classList.add("rails-table-preferences-table-column--dragging")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", key)
  }

  dragTableColumnOver(event) {
    event.preventDefault()

    const targetCell = event.currentTarget
    const targetKey = targetCell.dataset.railsTablePreferencesColumnKey
    if (!this.draggedTableColumnKey || !targetKey || targetKey === this.draggedTableColumnKey) return

    const placement = this.tableColumnPlacement(event, targetCell)
    this.moveColumnInSettings(this.draggedTableColumnKey, targetKey, placement)
    this.applyColumnOrder()
  }

  dropTableColumn(event) {
    event.preventDefault()
    this.refreshEditorFromSettings()
  }

  endTableColumnDrag(event) {
    event.currentTarget.classList.remove("rails-table-preferences-table-column--dragging")
    this.draggedTableColumnKey = null
    this.refreshEditorFromSettings()
  }

  tableColumnPlacement(event, cell) {
    const rect = cell.getBoundingClientRect()
    const offset = event.clientX - rect.left
    const columns = this.orderedColumnsFromSettings
    const draggedIndex = columns.findIndex((column) => column.key === this.draggedTableColumnKey)
    const targetIndex = columns.findIndex((column) => column.key === cell.dataset.railsTablePreferencesColumnKey)

    if (draggedIndex >= 0 && targetIndex >= 0) {
      if (draggedIndex < targetIndex) {
        return offset > rect.width * this.reorderActivationRatio ? "after" : "before"
      }

      if (draggedIndex > targetIndex) {
        return offset < rect.width * (1 - this.reorderActivationRatio) ? "before" : "after"
      }
    }

    return offset < rect.width / 2 ? "before" : "after"
  }

  moveColumnInSettings(draggedKey, targetKey, placement) {
    const columns = this.orderedColumnsFromSettings
    const draggedIndex = columns.findIndex((column) => column.key === draggedKey)
    const targetIndex = columns.findIndex((column) => column.key === targetKey)
    if (draggedIndex < 0 || targetIndex < 0) return

    const [draggedColumn] = columns.splice(draggedIndex, 1)
    const adjustedTargetIndex = columns.findIndex((column) => column.key === targetKey)
    const insertIndex = placement === "before" ? adjustedTargetIndex : adjustedTargetIndex + 1
    columns.splice(insertIndex, 0, draggedColumn)

    this.settingsValue = {
      ...this.settingsValue,
      columns: columns.map((column, index) => ({ ...column, order: (index + 1) * 10 }))
    }
  }

  installFilterControls() {
    this.headerCells.forEach((cell) => {
      const key = cell.dataset.railsTablePreferencesColumnKey
      const column = this.columnDefinitionByKey(key)
      if (!column?.filter) return
      if (cell.querySelector("[data-rails-table-preferences-filter-button]")) return

      const button = document.createElement("button")
      button.type = "button"
      button.className = "rails-table-preferences-filter-button"
      button.dataset.railsTablePreferencesFilterButton = "true"
      button.dataset.railsTablePreferencesColumnKey = key
      button.setAttribute("aria-label", `${this.filterLabelValue}: ${column.label || key}`)
      button.title = `${this.filterLabelValue}: ${column.label || key}`
      button.textContent = "▾"
      button.addEventListener("mousedown", (event) => event.stopPropagation())
      button.addEventListener("dragstart", (event) => event.preventDefault())
      button.addEventListener("click", (event) => this.toggleFilterPanel(event, cell, column))

      cell.appendChild(button)
    })

    this.syncFilterButtonStates()
  }

  toggleFilterPanel(event, headerCell, column) {
    event.preventDefault()
    event.stopPropagation()

    const key = column.key
    if (this.filterPanel?.dataset.railsTablePreferencesColumnKey === key) {
      this.closeFilterPanel()
      return
    }

    this.openFilterPanel(headerCell, column)
  }

  openFilterPanel(headerCell, column) {
    this.closeFilterPanel()

    const panel = document.createElement("div")
    panel.className = "rails-table-preferences-filter-panel"
    panel.dataset.railsTablePreferencesColumnKey = column.key
    panel.innerHTML = this.filterPanelHtml(column)
    panel.querySelector("[data-action='apply-filter']")?.addEventListener("click", (event) => {
      event.preventDefault()
      this.applyFilterPanel(column.key, panel)
    })
    panel.querySelector("[data-action='clear-filter']")?.addEventListener("click", (event) => {
      event.preventDefault()
      this.clearFilter(column.key)
    })
    panel.addEventListener("click", (event) => event.stopPropagation())

    document.body.appendChild(panel)
    this.positionFilterPanel(panel, headerCell)
    this.filterPanel = panel
    this.boundCloseFilterPanel = (event) => {
      if (!panel.contains(event.target) && !event.target.closest("[data-rails-table-preferences-filter-button]")) {
        this.closeFilterPanel()
      }
    }
    document.addEventListener("click", this.boundCloseFilterPanel)
  }

  filterPanelHtml(column) {
    const filter = column.filter || {}
    const condition = this.filterConditionFor(column.key)
    const operators = this.filterOperatorsFor(filter)
    const selectedOperator = condition.operator || operators[0] || "contains"

    return `
      <div class="rails-table-preferences-filter-panel__title">${this.escapeHtml(column.label || column.key)}</div>
      <label class="rails-table-preferences-filter-panel__field">
        ${this.escapeHtml(this.filterOperatorLabelValue)}
        <select data-field="operator">
          ${operators.map((operator) => `<option value="${this.escapeHtml(operator)}" ${operator === selectedOperator ? "selected" : ""}>${this.escapeHtml(this.filterOperatorText(operator))}</option>`).join("")}
        </select>
      </label>
      ${this.filterValueHtml(filter, condition, selectedOperator)}
      <div class="rails-table-preferences-filter-panel__actions">
        <button type="button" data-action="apply-filter">${this.escapeHtml(this.filterApplyLabelValue)}</button>
        <button type="button" data-action="clear-filter">${this.escapeHtml(this.filterClearLabelValue)}</button>
      </div>
    `
  }

  filterValueHtml(filter, condition, selectedOperator) {
    if (["blank", "present", "true", "false"].includes(selectedOperator)) return ""

    if (selectedOperator === "between") {
      return `
        <label class="rails-table-preferences-filter-panel__field">
          ${this.escapeHtml(this.filterFromLabelValue)}
          <input type="${this.filterInputType(filter)}" data-field="from" value="${this.escapeHtml(condition.from ?? "")}">
        </label>
        <label class="rails-table-preferences-filter-panel__field">
          ${this.escapeHtml(this.filterToLabelValue)}
          <input type="${this.filterInputType(filter)}" data-field="to" value="${this.escapeHtml(condition.to ?? "")}">
        </label>
      `
    }

    if (filter.type === "select" && Array.isArray(filter.options)) {
      const values = new Set(Array(condition.values || condition.value || []).map(String))
      return `
        <label class="rails-table-preferences-filter-panel__field">
          ${this.escapeHtml(this.filterValueLabelValue)}
          <select data-field="values" multiple>
            ${filter.options.map((option) => `<option value="${this.escapeHtml(option)}" ${values.has(String(option)) ? "selected" : ""}>${this.escapeHtml(option)}</option>`).join("")}
          </select>
        </label>
      `
    }

    return `
      <label class="rails-table-preferences-filter-panel__field">
        ${this.escapeHtml(this.filterValueLabelValue)}
        <input type="${this.filterInputType(filter)}" data-field="value" value="${this.escapeHtml(condition.value ?? "")}">
      </label>
    `
  }

  positionFilterPanel(panel, headerCell) {
    const rect = headerCell.getBoundingClientRect()
    panel.style.position = "absolute"
    panel.style.top = `${window.scrollY + rect.bottom + 4}px`
    panel.style.left = `${window.scrollX + rect.left}px`
    panel.style.zIndex = "1000"
  }

  applyFilterPanel(key, panel) {
    const operator = panel.querySelector("[data-field='operator']")?.value
    if (!operator) return

    const condition = { operator }

    if (operator === "between") {
      const from = panel.querySelector("[data-field='from']")?.value
      const to = panel.querySelector("[data-field='to']")?.value
      if (from) condition.from = from
      if (to) condition.to = to
    } else if (["blank", "present", "true", "false"].includes(operator)) {
      // Operator-only conditions intentionally have no value.
    } else {
      const valuesSelect = panel.querySelector("[data-field='values']")
      if (valuesSelect) {
        condition.values = Array.from(valuesSelect.selectedOptions).map((option) => option.value)
      } else {
        const value = panel.querySelector("[data-field='value']")?.value
        if (value) condition.value = value
      }
    }

    this.updateFilterCondition(key, condition)
    this.closeFilterPanel()
    this.apply()
  }

  clearFilter(key) {
    const filters = { ...(this.settingsValue?.filters || {}) }
    delete filters[key]
    this.settingsValue = { ...this.settingsValue, filters }
    this.closeFilterPanel()
    this.apply()
  }

  updateFilterCondition(key, condition) {
    this.settingsValue = {
      ...this.settingsValue,
      filters: {
        ...(this.settingsValue?.filters || {}),
        [key]: condition
      }
    }
  }

  closeFilterPanel() {
    if (this.boundCloseFilterPanel) {
      document.removeEventListener("click", this.boundCloseFilterPanel)
      this.boundCloseFilterPanel = null
    }

    if (this.filterPanel) {
      this.filterPanel.remove()
      this.filterPanel = null
    }
  }

  syncFilterButtonStates() {
    this.headerCells.forEach((cell) => {
      const key = cell.dataset.railsTablePreferencesColumnKey
      const button = cell.querySelector("[data-rails-table-preferences-filter-button]")
      if (!button) return

      const active = this.filterConditionFor(key).operator
      button.classList.toggle("rails-table-preferences-filter-button--active", Boolean(active))
      button.setAttribute("aria-pressed", active ? "true" : "false")
    })
  }

  filterConditionFor(key) {
    return this.settingsValue?.filters?.[key] || {}
  }

  filterOperatorsFor(filter) {
    if (Array.isArray(filter.operators) && filter.operators.length > 0) return filter.operators.map(String)

    switch (filter.type) {
      case "number":
        return ["equals", "gteq", "lteq", "gt", "lt", "blank", "present"]
      case "date":
        return ["equals", "gteq", "lteq", "between", "blank", "present"]
      case "select":
        return ["in", "not_in", "blank", "present"]
      case "boolean":
        return ["true", "false", "blank", "present"]
      default:
        return ["contains", "equals", "starts_with", "ends_with", "blank", "present"]
    }
  }

  filterInputType(filter) {
    switch (filter.type) {
      case "number":
        return "number"
      case "date":
        return "date"
      default:
        return "text"
    }
  }

  filterOperatorText(operator) {
    const labels = {
      contains: "含む",
      not_contains: "含まない",
      equals: "一致",
      not_equals: "不一致",
      starts_with: "で始まる",
      ends_with: "で終わる",
      in: "いずれか",
      not_in: "以外",
      gt: "より大きい",
      gteq: "以上",
      lt: "より小さい",
      lteq: "以下",
      between: "範囲",
      blank: "空白",
      present: "空白以外",
      true: "はい",
      false: "いいえ"
    }

    return labels[operator] || operator
  }

  refreshEditorFromSettings() {
    this.renderEditor()
    this.syncEditorWidthInputs()
    this.syncFilterButtonStates()
  }

  settingsFromEditor() {
    if (!this.hasEditorRowsTarget) return this.settingsValue

    const columns = this.editorRows.map((row, index) => {
      const key = row.dataset.railsTablePreferencesColumnKey
      const current = this.columnByKey(key) || {}

      return {
        key,
        visible: row.querySelector('[data-field="visible"]')?.checked ?? true,
        order: this.integerValue(row.querySelector('[data-field="order"]')?.value) ?? current.order ?? (index + 1) * 10,
        width: this.integerValue(row.querySelector('[data-field="width"]')?.value),
        truncate: this.integerValue(row.querySelector('[data-field="truncate"]')?.value),
        pinned: current.pinned === true
      }
    })

    return {
      ...this.settingsValue,
      columns,
      filters: this.settingsValue?.filters || {},
      sorts: this.settingsValue?.sorts || []
    }
  }

  applyColumn(column) {
    if (!column) return

    const key = column.key
    const cells = this.cellsFor(key)

    cells.forEach((cell) => {
      cell.hidden = column.visible === false

      cell.style.width = ""
      cell.style.maxWidth = ""
      cell.style.overflow = ""
      cell.style.textOverflow = ""
      cell.style.whiteSpace = ""
      delete cell.dataset.railsTablePreferencesTruncate

      if (column.width) {
        cell.style.width = `${column.width}px`
        cell.style.maxWidth = `${column.width}px`
      }

      if (column.truncate) {
        cell.dataset.railsTablePreferencesTruncate = column.truncate
        cell.style.overflow = "hidden"
        cell.style.textOverflow = "ellipsis"
        cell.style.whiteSpace = "nowrap"
        if (!cell.title) cell.title = cell.textContent.trim()
      }
    })
  }

  applyColumnOrder() {
    const orderedKeys = this.orderedColumnsFromSettings.map((column) => column.key)

    this.tableRows.forEach((row) => {
      const keyedCells = new Map(
        Array.from(row.children)
          .filter((cell) => cell.dataset.railsTablePreferencesColumnKey)
          .map((cell) => [cell.dataset.railsTablePreferencesColumnKey, cell])
      )

      orderedKeys.forEach((key) => {
        const cell = keyedCells.get(key)
        if (cell) row.appendChild(cell)
      })
    })
  }

  buildDefaultSettings() {
    return {
      columns: this.columnsValue.map((column, index) => ({
        key: column.key,
        label: column.label || column.key,
        visible: column.visible !== false,
        order: column.order ?? (index + 1) * 10,
        width: column.width,
        truncate: column.truncate,
        pinned: column.pinned === true,
        filter: column.filter,
        sortable: column.sortable
      })),
      filters: {},
      sorts: []
    }
  }

  mergeSettings(defaultSettings, savedSettings) {
    const savedColumns = new Map((savedSettings?.columns || []).map((column) => [column.key, column]))

    const columns = defaultSettings.columns.map((defaultColumn, index) => {
      const savedColumn = savedColumns.get(defaultColumn.key) || {}

      return {
        ...defaultColumn,
        ...savedColumn,
        label: defaultColumn.label,
        filter: defaultColumn.filter,
        sortable: defaultColumn.sortable,
        order: savedColumn.order ?? defaultColumn.order ?? (index + 1) * 10,
        visible: savedColumn.visible ?? defaultColumn.visible
      }
    })

    return {
      columns,
      filters: savedSettings?.filters || {},
      sorts: savedSettings?.sorts || []
    }
  }

  updateColumnSetting(key, attributes) {
    this.settingsValue = {
      ...this.settingsValue,
      columns: this.columnsFromSettings.map((column) => (
        column.key === key ? { ...column, ...attributes } : column
      ))
    }
  }

  preferenceUrl(name) {
    return `${this.collectionUrlValue}/${encodeURIComponent(name || "default")}`
  }

  setPresetNameInput(name) {
    if (this.hasPresetNameTarget) this.presetNameTarget.value = name
  }

  setDefaultPresetInput(value) {
    if (this.hasDefaultPresetTarget) this.defaultPresetTarget.checked = value === true
  }

  cellsFor(key) {
    const table = this.tableElement
    if (!table) return []

    return table.querySelectorAll(`[data-rails-table-preferences-column-key="${CSS.escape(key)}"]`)
  }

  columnByKey(key) {
    return this.columnsFromSettings.find((column) => column.key === key)
  }

  columnDefinitionByKey(key) {
    return this.columnsValue.find((column) => column.key === key) || this.columnByKey(key)
  }

  orderValue(column) {
    return Number.isFinite(Number(column.order)) ? Number(column.order) : Number.MAX_SAFE_INTEGER
  }

  integerValue(value) {
    if (value === undefined || value === null || value === "") return null

    const integer = Number.parseInt(value, 10)
    return Number.isNaN(integer) ? null : integer
  }

  escapeHtml(value) {
    const span = document.createElement("span")
    span.textContent = value
    return span.innerHTML
  }

  get columnsFromSettings() {
    return this.settingsValue?.columns || []
  }

  get orderedColumnsFromSettings() {
    return this.columnsFromSettings.slice().sort((left, right) => this.orderValue(left) - this.orderValue(right))
  }

  get normalizedResizeHandleWidth() {
    const value = Number(this.resizeHandleWidthValue)
    return Number.isFinite(value) && value > 0 ? value : 10
  }

  get normalizedReorderSensitivity() {
    const value = Number(this.reorderSensitivityValue)
    return Number.isFinite(value) && value > 0 ? value : 1
  }

  get reorderActivationRatio() {
    return Math.max(0.25, Math.min(0.5, 0.5 / this.normalizedReorderSensitivity))
  }

  get currentPresetName() {
    if (!this.hasPresetNameTarget) return this.nameValue || "default"

    return this.presetNameTarget.value.trim() || "default"
  }

  get defaultPresetChecked() {
    return this.hasDefaultPresetTarget ? this.defaultPresetTarget.checked : false
  }

  get editorRows() {
    if (!this.hasEditorRowsTarget) return []

    return Array.from(this.editorRowsTarget.querySelectorAll("[data-rails-table-preferences-column-key]"))
  }

  get tableElement() {
    return this.element.tagName === "TABLE" ? this.element : this.element.querySelector("table")
  }

  get headerCells() {
    const table = this.tableElement
    if (!table) return []

    return Array.from(table.querySelectorAll("th[data-rails-table-preferences-column-key]"))
  }

  get tableRows() {
    const table = this.tableElement
    if (!table) return []

    return table.querySelectorAll("tr")
  }

  get jsonHeaders() {
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "X-CSRF-Token": this.csrfToken
    }
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }
}
