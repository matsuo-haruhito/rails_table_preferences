import { Controller } from "@hotwired/stimulus"

// Applies saved table display preferences to a server-rendered table.
//
// Expected markup:
//   <table data-controller="rails-table-preferences" ...>
//     <th data-rails-table-preferences-column-key="customer_code">...</th>
//     <td data-rails-table-preferences-column-key="customer_code">...</td>
//   </table>
export default class extends Controller {
  static values = {
    tableKey: String,
    name: { type: String, default: "default" },
    url: String,
    settings: Object
  }

  connect() {
    this.apply()
  }

  apply() {
    this.columns.forEach((column) => {
      this.applyColumn(column)
    })
  }

  async save(event) {
    if (event) event.preventDefault()

    const response = await fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({ settings: this.settingsValue })
    })

    if (!response.ok) {
      throw new Error(`Failed to save table preferences: ${response.status}`)
    }

    const payload = await response.json()
    this.settingsValue = payload.settings
    this.apply()
  }

  applyColumn(column) {
    const key = column.key
    const cells = this.cellsFor(key)

    cells.forEach((cell) => {
      cell.hidden = column.visible === false

      if (column.width) {
        cell.style.width = `${column.width}px`
        cell.style.maxWidth = `${column.width}px`
      }

      if (column.truncate) {
        cell.dataset.railsTablePreferencesTruncate = column.truncate
        cell.style.overflow = "hidden"
        cell.style.textOverflow = "ellipsis"
        cell.style.whiteSpace = "nowrap"
      }
    })
  }

  cellsFor(key) {
    return this.element.querySelectorAll(`[data-rails-table-preferences-column-key="${CSS.escape(key)}"]`)
  }

  get columns() {
    return this.settingsValue?.columns || []
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }
}
