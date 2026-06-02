import RailsTablePreferencesBaseController from "../controllers/rails_table_preferences_controller"

export default class RailsTablePreferencesController extends RailsTablePreferencesBaseController {
  static values = {
    ...RailsTablePreferencesBaseController.values,
    filterOperatorLabels: { type: Object, default: {} }
  }

  renderPresetOptions() {
    if (!this.hasPresetSelectTarget) return
    this.presetSelectTarget.innerHTML = ""
    const presets = this.presets.length ? this.presets : [{ name: this.currentPresetName, default: false, editable: true }]
    presets.forEach((preset) => this.presetSelectTarget.appendChild(this.buildPresetOption(preset)))
    this.presetSelectTarget.value = this.currentPresetOptionValue
    if (this.presetSelectTarget.value !== this.currentPresetOptionValue) this.presetSelectTarget.value = this.currentPresetName
    this.syncDeletePresetButtonContext()
  }

  buildPresetOption(preset) {
    const option = super.buildPresetOption(preset)
    const name = preset.name || "default"
    const scopeType = preset.scope_type || "owner"
    const scopeKey = preset.scope_key || ""
    option.value = this.presetOptionValue({ name, scopeType, scopeKey })
    option.dataset.presetName = name
    option.dataset.scopeType = scopeType
    option.dataset.scopeKey = scopeKey
    return option
  }

  async selectPreset(event) {
    if (event) event.preventDefault()
    const selectedOption = this.presetSelectTarget.selectedOptions?.[0]
    const name = selectedOption?.dataset.presetName || this.presetSelectTarget.value || "default"
    const scope = this.scopeFromPresetOption(selectedOption)

    await this.withBusyStatus(async () => {
      const response = await fetch(this.preferenceUrl(name, scope), { headers: { "Accept": "application/json" } })
      if (!response.ok) throw new Error(`Failed to load table preference preset: ${response.status}`)
      this.applyPreferencePayload(await response.json())
    }, {
      busyLabel: this.loadingStatusLabelValue,
      successLabel: this.loadedStatusLabelValue,
      errorLabel: this.loadingFailedStatusLabelValue
    })
  }

  applyPreferencePayload(payload) {
    super.applyPreferencePayload(payload)
    this.currentPresetScopeType = payload.scope_type || "owner"
    this.currentPresetScopeKey = payload.scope_key || ""
    this.urlValue = this.preferenceUrl(payload.name, {
      scopeType: this.currentPresetScopeType,
      scopeKey: this.currentPresetScopeKey
    })
  }

  preferenceUrl(name, scope = {}) {
    const baseUrl = super.preferenceUrl(name)
    const [path, query = ""] = baseUrl.split("?")
    const params = new URLSearchParams(query)
    const scopeType = scope.scopeType || scope.scope_type || ""
    const scopeKey = scope.scopeKey || scope.scope_key || ""

    if (scopeType && scopeType !== "owner") params.set("scope_type", scopeType)
    else params.delete("scope_type")

    if (scopeKey) params.set("scope_key", scopeKey)
    else params.delete("scope_key")

    const queryString = params.toString()
    return queryString ? `${path}?${queryString}` : path
  }

  presetOptionValue({ name, scopeType = "owner", scopeKey = "" }) {
    return [name || "default", scopeType || "owner", scopeKey || ""].map((value) => encodeURIComponent(value)).join("|")
  }

  scopeFromPresetOption(option) {
    return {
      scopeType: option?.dataset.scopeType || "owner",
      scopeKey: option?.dataset.scopeKey || ""
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

  filterOperatorText(operator) {
    const key = String(operator)
    const override = this.filterOperatorLabelsValue?.[key]
    if (override !== undefined && override !== null && String(override).trim() !== "") return String(override)
    return super.filterOperatorText(key)
  }

  get currentPresetOptionValue() {
    return this.presetOptionValue({
      name: this.currentPresetName,
      scopeType: this.currentPresetScopeType || "owner",
      scopeKey: this.currentPresetScopeKey || ""
    })
  }

  get currentDeletePresetDisplayName() {
    const selectedOption = this.hasPresetSelectTarget ? this.presetSelectTarget.selectedOptions?.[0] : null
    if (selectedOption && selectedOption.dataset.presetName === this.currentPresetName) {
      return this.normalizedPresetOptionText(selectedOption)
    }
    return this.currentPresetName
  }
}
