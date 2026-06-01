import RailsTablePreferencesBaseController from "../controllers/rails_table_preferences_controller"

const DATE_TIME_FILTER_TYPES = new Set(["datetime", "datetime-local", "time"])

export default class RailsTablePreferencesController extends RailsTablePreferencesBaseController {
  static values = {
    ...RailsTablePreferencesBaseController.values,
    filterOperatorLabels: { type: Object, default: {} }
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
