import RailsTablePreferencesController from "./controller.js"

export default class RailsTablePreferencesPresetSelectRecoveryController extends RailsTablePreferencesController {
  async selectPreset(event) {
    if (this.busy) return null

    const appliedPresetName = this.nameValue || this.currentPresetName
    const result = await super.selectPreset(event)

    if (this.statusState !== "success") this.restorePresetSelectToAppliedPreset(appliedPresetName)
    return result
  }

  restorePresetSelectToAppliedPreset(name) {
    if (!this.hasPresetSelectTarget) return

    this.presetSelectTarget.value = name || "default"
    this.syncDeletePresetButtonContext()
  }
}
