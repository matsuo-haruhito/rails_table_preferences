import PackageController from "./controller"

export default class RailsTablePreferencesPresetSearchController extends PackageController {
  static values = {
    ...PackageController.values,
    presetSearchLabel: { type: String, default: "保存済み設定を検索" },
    presetSearchPlaceholder: { type: String, default: "設定名やスコープで絞り込み" },
    presetNoSearchResultsLabel: { type: String, default: "一致する保存済み設定はありません。検索語を変更してください。" },
    presetSearchThreshold: { type: Number, default: 8 }
  }

  renderPresetOptions() {
    if (!this.hasPresetSelectTarget) return

    this.ensurePresetSearchControl()

    const allPresets = this.presets.length ? this.presets : [{ name: this.currentPresetName, default: false, editable: true }]
    const shouldShowSearch = allPresets.length >= this.normalizedPresetSearchThreshold
    if (!shouldShowSearch && this.presetSearchInput) this.presetSearchInput.value = ""

    const query = shouldShowSearch ? this.presetSearchQuery : ""
    const visiblePresets = query ? allPresets.filter((preset) => this.presetMatchesSearch(preset, query)) : allPresets

    this.presetSelectTarget.innerHTML = ""
    if (visiblePresets.length > 0) this.appendPresetOptions(visiblePresets)

    this.syncPresetSelectValue(visiblePresets)
    this.syncPresetSearchState({ query, visibleCount: visiblePresets.length, enabled: shouldShowSearch })
    this.syncDeletePresetButtonContext()
  }

  appendPresetOptions(presets) {
    const groups = this.groupPresetsForSelect(presets)
    if (groups.length <= 1) {
      presets.forEach((preset) => this.presetSelectTarget.appendChild(this.buildPresetOption(preset)))
      return
    }

    groups.forEach((group) => {
      const optgroup = document.createElement("optgroup")
      optgroup.label = group.label
      group.presets.forEach((preset) => optgroup.appendChild(this.buildPresetOption(preset)))
      this.presetSelectTarget.appendChild(optgroup)
    })
  }

  syncPresetSelectValue(visiblePresets) {
    if (visiblePresets.some((preset) => (preset.name || "default") === this.currentPresetName)) {
      this.presetSelectTarget.value = this.currentPresetName
    }
  }

  ensurePresetSearchControl() {
    if (this.presetSearchControl || !this.hasPresetSelectTarget) return

    const wrapper = document.createElement("div")
    wrapper.className = "rails-table-preferences-editor__preset-search"
    wrapper.dataset.railsTablePreferencesPresetSearch = "true"

    const label = document.createElement("label")
    label.className = "rails-table-preferences-editor__search"
    const labelText = document.createElement("span")
    labelText.textContent = this.presetSearchLabelValue
    const input = document.createElement("input")
    input.type = "search"
    input.placeholder = this.presetSearchPlaceholderValue
    input.setAttribute("aria-label", this.presetSearchLabelValue)
    input.dataset.railsTablePreferencesPresetSearchInput = "true"
    input.addEventListener("input", () => this.renderPresetOptions())
    label.append(labelText, input)

    const empty = document.createElement("p")
    empty.className = "rails-table-preferences-editor__search-empty"
    empty.dataset.railsTablePreferencesPresetSearchEmpty = "true"
    empty.hidden = true
    empty.textContent = this.presetNoSearchResultsLabelValue

    wrapper.append(label, empty)
    this.presetSelectTarget.before(wrapper)
  }

  syncPresetSearchState({ query, visibleCount, enabled }) {
    if (this.presetSearchControl) this.presetSearchControl.hidden = !enabled
    if (this.presetSearchInput) this.presetSearchInput.disabled = this.busy || !enabled
    if (this.presetSearchEmptyMessage) this.presetSearchEmptyMessage.hidden = !enabled || !query || visibleCount > 0
    if (this.hasPresetSelectTarget) this.presetSelectTarget.disabled = this.busy || (enabled && Boolean(query) && visibleCount === 0)
  }

  setBusyState(busy) {
    super.setBusyState(busy)
    this.syncPresetSearchState({
      query: this.presetSearchQuery,
      visibleCount: this.visiblePresetOptionCount,
      enabled: !this.presetSearchControl?.hidden
    })
  }

  presetMatchesSearch(preset, query) {
    return this.presetSearchText(preset).includes(query)
  }

  presetSearchText(preset) {
    const scopeType = preset.scope_type || "owner"
    const scopeLabel = preset.scope_label || this.scopeFallbackLabel(scopeType)
    return [preset.name || "default", scopeLabel, scopeType]
      .filter(Boolean)
      .join(" ")
      .toLocaleLowerCase()
  }

  get presetSearchControl() {
    return this.element.querySelector("[data-rails-table-preferences-preset-search]")
  }

  get presetSearchInput() {
    return this.presetSearchControl?.querySelector("[data-rails-table-preferences-preset-search-input]")
  }

  get presetSearchEmptyMessage() {
    return this.presetSearchControl?.querySelector("[data-rails-table-preferences-preset-search-empty]")
  }

  get presetSearchQuery() {
    return String(this.presetSearchInput?.value || "").trim().toLocaleLowerCase()
  }

  get visiblePresetOptionCount() {
    return this.presetSelectTarget?.querySelectorAll("option").length || 0
  }

  get normalizedPresetSearchThreshold() {
    const rawValue = this.element?.dataset?.railsTablePreferencesPresetSearchThresholdValue
    if (rawValue !== undefined && String(rawValue).trim() === "") return 8

    const threshold = Number(this.presetSearchThresholdValue)
    if (!Number.isFinite(threshold)) return 8
    return Math.max(0, Math.floor(threshold))
  }
}
