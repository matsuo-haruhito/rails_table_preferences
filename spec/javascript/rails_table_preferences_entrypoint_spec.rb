# frozen_string_literal: true

require "fileutils"
require "open3"
require "spec_helper"
require "tmpdir"

RSpec.describe "rails_table_preferences JavaScript entrypoints" do
  let(:repo_root) { File.expand_path("../..", __dir__) }

  def build_entrypoint_sandbox
    Dir.mktmpdir("rails-table-preferences-entrypoints") do |tmpdir|
      package_dir = File.join(tmpdir, "app/javascript/rails_table_preferences")
      controller_dir = File.join(tmpdir, "app/javascript/controllers")
      stimulus_dir = File.join(tmpdir, "node_modules/@hotwired/stimulus")
      package_root = File.join(tmpdir, "node_modules/rails_table_preferences")

      FileUtils.mkdir_p(package_dir)
      FileUtils.mkdir_p(controller_dir)
      FileUtils.mkdir_p(stimulus_dir)

      File.write(File.join(tmpdir, "package.json"), "{\n  \"type\": \"module\"\n}\n")
      File.write(
        File.join(package_dir, "index.js"),
        File.read(File.join(repo_root, "app/javascript/rails_table_preferences/index.js"))
          .gsub('"./controller"', '"./controller.js"')
      )
      File.write(
        File.join(package_dir, "controller.js"),
        File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js"))
          .gsub('"../controllers/rails_table_preferences_controller"', '"../controllers/rails_table_preferences_controller.js"')
      )
      FileUtils.cp(
        File.join(repo_root, "app/javascript/controllers/rails_table_preferences_controller.js"),
        File.join(controller_dir, "rails_table_preferences_controller.js")
      )
      File.write(
        File.join(stimulus_dir, "package.json"),
        "{\n  \"name\": \"@hotwired/stimulus\",\n  \"type\": \"module\",\n  \"exports\": \"./index.js\"\n}\n"
      )
      File.write(File.join(stimulus_dir, "index.js"), "export class Controller {}\n")

      FileUtils.mkdir_p(package_root)
      File.write(File.join(package_root, "package.json"), File.read(File.join(repo_root, "package.json")))
      FileUtils.cp_r(File.join(tmpdir, "app"), package_root)

      yield tmpdir
    end
  end

  def run_node_entrypoint_check(*paths, script:, chdir: nil)
    options = chdir ? { chdir: chdir } : {}
    stdout, stderr, status = Open3.capture3("node", "--input-type=module", "-e", script, *paths, **options)

    expect(status).to be_success, <<~MESSAGE
      expected documented JavaScript entrypoints to load successfully

      stdout:
      #{stdout}

      stderr:
      #{stderr}
    MESSAGE
  end

  it "loads the documented controller entrypoint as a module" do
    build_entrypoint_sandbox do |tmpdir|
      controller_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const controllerModule = await import(controllerUrl)

        if (typeof controllerModule.default !== "function") {
          throw new Error("controller entrypoint did not export a default controller class")
        }
      JS

      run_node_entrypoint_check(controller_entrypoint_path, script:)
    end
  end

  it "loads the package root entrypoint and keeps the documented named export wired to the controller export" do
    build_entrypoint_sandbox do |tmpdir|
      index_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/index.js")
      controller_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const indexUrl = pathToFileURL(process.argv[1]).href
        const controllerUrl = pathToFileURL(process.argv[2]).href

        const indexModule = await import(indexUrl)
        const controllerModule = await import(controllerUrl)

        if (indexModule.default !== controllerModule.default) {
          throw new Error("package root default export no longer matches the controller entrypoint")
        }

        if (indexModule.RailsTablePreferencesController !== controllerModule.default) {
          throw new Error("package root named export no longer matches the controller entrypoint")
        }
      JS

      run_node_entrypoint_check(index_entrypoint_path, controller_entrypoint_path, script:)
    end
  end

  it "loads documented package exports through Node package resolution" do
    build_entrypoint_sandbox do |tmpdir|
      script = <<~JS
        const indexModule = await import("rails_table_preferences")
        const controllerModule = await import("rails_table_preferences/controller")

        if (indexModule.default !== controllerModule.default) {
          throw new Error("package export map root no longer resolves to the controller entrypoint")
        }

        if (indexModule.RailsTablePreferencesController !== controllerModule.default) {
          throw new Error("package export map named export no longer resolves to the controller entrypoint")
        }
      JS

      run_node_entrypoint_check(script:, chdir: tmpdir)
    end
  end

  it "keeps package-only controller values out of the copied controller contract" do
    build_entrypoint_sandbox do |tmpdir|
      base_controller_path = File.join(tmpdir, "app/javascript/controllers/rails_table_preferences_controller.js")
      package_controller_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const baseUrl = pathToFileURL(process.argv[1]).href
        const packageUrl = pathToFileURL(process.argv[2]).href
        const { default: BaseController } = await import(baseUrl)
        const { default: PackageController } = await import(packageUrl)

        if (!(PackageController.prototype instanceof BaseController)) {
          throw new Error("package entrypoint no longer subclasses the copied controller")
        }

        if (Object.hasOwn(BaseController.values, "filterOperatorLabels")) {
          throw new Error("package-only filterOperatorLabels value leaked into the copied controller")
        }

        if (!Object.hasOwn(PackageController.values, "filterOperatorLabels")) {
          throw new Error("package entrypoint no longer exposes filterOperatorLabels as a package-only value")
        }
      JS

      run_node_entrypoint_check(base_controller_path, package_controller_path, script:)
    end
  end

  it "uses package entrypoint filter operator label overrides and falls back to bundled labels" do
    build_entrypoint_sandbox do |tmpdir|
      controller_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const controller = new ControllerClass()

        controller.filterOperatorLabelsValue = {
          contains: "Includes",
          between: 42,
          equals: "",
          blank: null,
          present: undefined
        }

        if (controller.filterOperatorText("contains") !== "Includes") {
          throw new Error("filterOperatorLabelsValue override was not used for contains")
        }

        if (controller.filterOperatorText("between") !== "42") {
          throw new Error("filterOperatorLabelsValue override was not stringified")
        }

        if (controller.filterOperatorText("equals") !== "一致") {
          throw new Error("blank override did not fall back to the bundled equals label")
        }

        if (controller.filterOperatorText("blank") !== "空白") {
          throw new Error("null override did not fall back to the bundled blank label")
        }

        if (controller.filterOperatorText("present") !== "空白以外") {
          throw new Error("undefined override did not fall back to the bundled present label")
        }

        if (controller.filterOperatorText("starts_with") !== "で始まる") {
          throw new Error("missing override did not fall back to the bundled starts_with label")
        }
      JS

      run_node_entrypoint_check(controller_entrypoint_path, script:)
    end
  end

  it "preserves current column metadata after package editor rows are applied" do
    build_entrypoint_sandbox do |tmpdir|
      controller_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const controller = new ControllerClass()
        const input = (value, checked = true) => ({ value, checked })
        const row = (key, fields) => ({
          dataset: { railsTablePreferencesColumnKey: key },
          querySelector(selector) { return fields[selector] || null }
        })

        controller.defaultSettings = {
          columns: [
            { key: "name", label: "Current name", visible: true, order: 10, width: 120, truncate: 20, overflow: "wrap", pinned: true, filter: { type: "text" }, sortable: true },
            { key: "status", label: "Current status", visible: true, order: 20, overflow: "clip", pinned: false, filter: { type: "select", options: ["open"] }, sortable: false }
          ],
          filters: {},
          sorts: []
        }
        controller.settingsValue = {
          columns: [
            { key: "name", label: "Stale name", visible: false, order: 99, width: 44, truncate: 5, overflow: "ellipsis", pinned: false, filter: { type: "number" }, sortable: false },
            { key: "status", label: "Stale status", visible: true, order: 77, width: 50, overflow: "nowrap", pinned: true, filter: { type: "boolean" }, sortable: true }
          ],
          filters: { name: { operator: "contains", value: "Acme" } },
          sorts: [{ key: "name", direction: "desc" }]
        }
        Object.defineProperty(controller, "hasEditorRowsTarget", { value: true })
        Object.defineProperty(controller, "editorRows", { value: [
          row("name", {
            '[data-field="visible"]': input("", true),
            '[data-field="order"]': input("30"),
            '[data-field="width"]': input(""),
            '[data-field="truncate"]': input("12")
          }),
          row("status", {
            '[data-field="visible"]': input("", false),
            '[data-field="order"]': input("40"),
            '[data-field="width"]': input("88"),
            '[data-field="truncate"]': input("")
          })
        ]})

        const nextSettings = controller.settingsFromEditor()
        const [nameColumn, statusColumn] = nextSettings.columns

        if (nameColumn.label !== "Current name" || nameColumn.overflow !== "wrap" || nameColumn.filter.type !== "text" || nameColumn.sortable !== true || nameColumn.pinned !== true) {
          throw new Error("current name column metadata was not preserved after editor apply")
        }

        if (nameColumn.visible !== true || nameColumn.order !== 30 || nameColumn.width !== null || nameColumn.truncate !== 12) {
          throw new Error("editable name column fields were not preserved after editor apply")
        }

        if (statusColumn.label !== "Current status" || statusColumn.overflow !== "clip" || statusColumn.filter.type !== "select" || statusColumn.sortable !== false || statusColumn.pinned !== false) {
          throw new Error("current status column metadata was not preserved after editor apply")
        }

        if (statusColumn.visible !== false || statusColumn.order !== 40 || statusColumn.width !== 88 || statusColumn.truncate !== null) {
          throw new Error("editable status column fields were not preserved after editor apply")
        }

        if (nextSettings.filters.name.value !== "Acme" || nextSettings.sorts[0].direction !== "desc") {
          throw new Error("filter or sort state was not preserved after editor apply")
        }
      JS

      run_node_entrypoint_check(controller_entrypoint_path, script:)
    end
  end

  it "uses the editor instance prefix in package filter panel ids when present" do
    build_entrypoint_sandbox do |tmpdir|
      controller_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const first = new ControllerClass()
        const second = new ControllerClass()
        first.tableKeyValue = "orders"
        second.tableKeyValue = "orders"
        first.editorIdPrefixValue = "rails-table-preferences-orders-default-first"
        second.editorIdPrefixValue = "rails-table-preferences-orders-default-second"

        const firstId = first.filterPanelId("status")
        const secondId = second.filterPanelId("status")

        if (firstId === secondId) {
          throw new Error("same table and column produced duplicate filter panel ids")
        }

        if (!firstId.endsWith("first-status") || !secondId.endsWith("second-status")) {
          throw new Error("filter panel ids did not include the editor instance prefix")
        }

        const fallback = new ControllerClass()
        fallback.tableKeyValue = "orders"
        if (fallback.filterPanelId("status") !== "rails-table-preferences-filter-panel-orders-status") {
          throw new Error("filter panel id no longer falls back to table key")
        }
      JS

      run_node_entrypoint_check(controller_entrypoint_path, script:)
    end
  end

  it "preserves host-provided sortable header titles while keeping generated sort hints for untitled headers" do
    build_entrypoint_sandbox do |tmpdir|
      controller_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const indicator = () => ({ textContent: "" })
        const cell = ({ key, title = "" }) => {
          const sortIndicator = indicator()
          return {
            title,
            dataset: { railsTablePreferencesColumnKey: key },
            attributes: {},
            sortIndicator,
            hasAttribute(name) { return name === "title" && title !== "" },
            classList: { add() {}, toggle() {} },
            addEventListener() {},
            appendChild(node) { this.sortIndicator = node },
            querySelector(selector) {
              return selector === "[data-rails-table-preferences-sort-indicator]" ? this.sortIndicator : null
            },
            setAttribute(name, value) { this.attributes[name] = value }
          }
        }

        const hostTitleCell = cell({ key: "account", title: "Business owner help" })
        const generatedHintCell = cell({ key: "total" })
        const controller = new ControllerClass()
        let activeSort = null

        Object.defineProperty(controller, "headerCells", { value: [hostTitleCell, generatedHintCell] })
        controller.columnDefinitionByKey = () => ({ sortable: true })
        controller.sortFor = (key) => activeSort?.key === key ? activeSort : undefined
        controller.sortAscLabelValue = "Sort ascending"
        controller.sortDescLabelValue = "Sort descending"
        controller.sortClearLabelValue = "Clear sort"

        controller.installSortControls()

        if (hostTitleCell.title !== "Business owner help") {
          throw new Error("host title was overwritten during sort control install")
        }

        if (generatedHintCell.title !== "Sort ascending") {
          throw new Error("generated sort hint was not applied to an untitled sortable header")
        }

        activeSort = { key: "account", direction: "desc" }
        controller.syncSortStates()

        if (hostTitleCell.title !== "Business owner help") {
          throw new Error("host title was overwritten during sort state sync")
        }

        if (hostTitleCell.attributes["aria-sort"] !== "descending") {
          throw new Error("aria-sort no longer tracks the active descending sort")
        }

        if (hostTitleCell.sortIndicator.textContent !== "▼") {
          throw new Error("sort indicator no longer tracks the active descending sort")
        }
      JS

      run_node_entrypoint_check(controller_entrypoint_path, script:)
    end
  end
end
