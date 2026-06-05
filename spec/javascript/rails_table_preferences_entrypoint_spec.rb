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

  it "dispatches public controller lifecycle events with stable detail payloads" do
    build_entrypoint_sandbox do |tmpdir|
      controller_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const controller = new ControllerClass()
        const events = []

        controller.dispatch = (name, options = {}) => events.push({ name, detail: options.detail })
        controller.tableKeyValue = "orders"
        controller.nameValue = "default"
        controller.settingsValue = { columns: [{ key: "total", visible: true }], filters: {}, sorts: [] }
        controller.hasPresetNameTarget = false
        controller.settingsFromEditor = () => ({ columns: [{ key: "total", visible: false }], filters: { total: { operator: "gt", value: "100" } }, sorts: [] })
        controller.apply = () => {}

        controller.applyFromEditor({ preventDefault() {} })

        const applied = events.find((event) => event.name === "applied")
        if (!applied) throw new Error("applied event was not dispatched")
        if (applied.detail.tableKey !== "orders") throw new Error("applied event missing tableKey")
        if (applied.detail.name !== "default") throw new Error("applied event missing preset name")
        if (applied.detail.action !== "apply") throw new Error("applied event missing action")
        if (applied.detail.settings.filters.total.value !== "100") throw new Error("applied event missing settings snapshot")

        await controller.withPreferenceAction("save", async () => {
          controller.handleOperationError(new Error("boom"), "Save failed")
        })

        const failure = events.find((event) => event.name === "error")
        if (!failure) throw new Error("error event was not dispatched")
        if (failure.detail.action !== "save") throw new Error("error event missing stable action")
        if (failure.detail.message !== "Save failed") throw new Error("error event missing stable message")
        if (Object.prototype.hasOwnProperty.call(failure.detail, "error")) {
          throw new Error("error event leaked the Error object")
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

  it "includes the selected preset display name in delete confirmation and button context" do
    build_entrypoint_sandbox do |tmpdir|
      controller_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const controller = new ControllerClass()
        const selectedOption = {
          value: "operations",
          textContent: "operations [ロール:運用] *"
        }
        const deleteButton = {
          textContent: "削除",
          title: "",
          attributes: {},
          setAttribute(name, value) { this.attributes[name] = value }
        }

        controller.deleteConfirmLabelValue = "この保存済み設定を削除します。よろしいですか？"
        Object.defineProperty(controller, "hasPresetSelectTarget", { value: true })
        Object.defineProperty(controller, "presetSelectTarget", {
          value: { selectedOptions: [selectedOption] }
        })
        Object.defineProperty(controller, "hasPresetNameTarget", { value: true })
        Object.defineProperty(controller, "presetNameTarget", { value: { value: "operations" } })

        const message = controller.deletePresetConfirmationMessage()

        if (!message.includes("この保存済み設定を削除します。よろしいですか？")) {
          throw new Error("delete confirmation lost the locale-backed confirmation copy")
        }

        if (!message.includes("operations [ロール:運用]")) {
          throw new Error("delete confirmation no longer includes the selected scoped preset display name")
        }

        if (message.includes("*")) {
          throw new Error("delete confirmation should not include the default preset marker")
        }

        controller.updateDeletePresetButtonContext(deleteButton)

        if (deleteButton.title !== message) {
          throw new Error("delete button title no longer matches the delete confirmation message")
        }

        if (deleteButton.attributes["aria-label"] !== `削除: ${message}`) {
          throw new Error("delete button aria-label no longer exposes the same delete target context")
        }

        controller.deleteConfirmLabelValue = ""

        if (controller.deletePresetConfirmationMessage() !== "operations [ロール:運用]") {
          throw new Error("empty delete confirmation override should keep the preset display name")
        }
      JS

      run_node_entrypoint_check(controller_entrypoint_path, script:)
    end
  end

  it "keeps read-only presets from exposing a delete action" do
    build_entrypoint_sandbox do |tmpdir|
      controller_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const controller = new ControllerClass()
        const deleteButton = {
          disabled: false,
          textContent: "削除",
          title: "",
          attributes: {},
          setAttribute(name, value) { this.attributes[name] = value }
        }

        controller.currentPreferenceEditable = false
        controller.deleteConfirmLabelValue = "この保存済み設定を削除します。よろしいですか？"
        Object.defineProperty(controller, "element", {
          value: {
            querySelectorAll(selector) {
              if (selector === "[data-action~='rails-table-preferences#saveFromEditor']") return []
              if (selector === "[data-action~='rails-table-preferences#deletePreset']") return [deleteButton]
              return []
            }
          }
        })
        Object.defineProperty(controller, "hasDefaultPresetTarget", { value: false })
        Object.defineProperty(controller, "hasReadOnlyHintTarget", { value: false })

        controller.syncPresetEditingState()

        if (deleteButton.disabled !== true) {
          throw new Error("read-only preset delete action is no longer disabled")
        }

        if (!deleteButton.attributes["aria-label"]?.includes("この保存済み設定を削除します。よろしいですか？")) {
          throw new Error("disabled delete action lost its explanatory context")
        }
      JS

      run_node_entrypoint_check(controller_entrypoint_path, script:)
    end
  end

  it "clears filters and sorts without replacing display column settings" do
    build_entrypoint_sandbox do |tmpdir|
      controller_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const controller = new ControllerClass()
        const columns = [
          { key: "status", visible: false, order: 20, width: 180, overflow: "wrap" },
          { key: "created_at", visible: true, order: 10, width: 120 }
        ]
        let closedPanel = false
        let applied = false

        controller.busy = false
        controller.settingsValue = {
          columns,
          filters: { status: { operator: "equals", value: "pending" } },
          sorts: [{ key: "created_at", direction: "desc" }]
        }
        controller.closeFilterPanel = () => { closedPanel = true }
        controller.apply = () => { applied = true }

        controller.clearFiltersAndSorts({ preventDefault() {} })

        if (controller.settingsValue.columns !== columns) {
          throw new Error("display column settings were replaced")
        }

        if (Object.keys(controller.settingsValue.filters).length !== 0) {
          throw new Error("filters were not cleared")
        }

        if (controller.settingsValue.sorts.length !== 0) {
          throw new Error("sorts were not cleared")
        }

        if (!closedPanel || !applied) {
          throw new Error("clear action did not close the filter panel and re-apply table state")
        }
      JS

      run_node_entrypoint_check(controller_entrypoint_path, script:)
    end
  end
end
