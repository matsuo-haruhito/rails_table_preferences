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

        if (Object.hasOwn(BaseController.values, "dirtyStateLabel")) {
          throw new Error("package-only dirtyStateLabel value leaked into the copied controller")
        }

        if (!Object.hasOwn(PackageController.values, "dirtyStateLabel")) {
          throw new Error("package entrypoint no longer exposes dirtyStateLabel as a package-only value")
        }

        if (BaseController.targets.includes("dirtyState")) {
          throw new Error("package-only dirtyState target leaked into the copied controller")
        }

        if (!PackageController.targets.includes("dirtyState")) {
          throw new Error("package entrypoint no longer exposes dirtyState as a package-only target")
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

  it "tracks package entrypoint dirty state without using the async status region" do
    build_entrypoint_sandbox do |tmpdir|
      controller_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const dirtyElements = []
        const statusTarget = { parentNode: { insertBefore(element) { dirtyElements.push(element) } } }
        const editorRowsTarget = {
          addEventListener() {},
          removeEventListener() {},
          querySelectorAll() { return [] }
        }
        const controller = new ControllerClass()
        let currentSettings = { columns: [{ key: "name", visible: true, order: 10 }], filters: {}, sorts: [] }

        globalThis.document = {
          createElement() {
            return {
              className: "",
              dataset: {},
              attributes: {},
              hidden: false,
              textContent: "",
              setAttribute(name, value) { this.attributes[name] = value }
            }
          }
        }
        controller.element = { appendChild(element) { dirtyElements.push(element) } }
        controller.dirtyStateLabelValue = "Unsaved changes"
        Object.defineProperty(controller, "hasDirtyStateTarget", { get() { return dirtyElements.length > 0 } })
        Object.defineProperty(controller, "dirtyStateTarget", { get() { return dirtyElements[0] } })
        Object.defineProperty(controller, "hasStatusTarget", { get() { return true } })
        Object.defineProperty(controller, "statusTarget", { get() { return statusTarget } })
        Object.defineProperty(controller, "hasEditorRowsTarget", { get() { return true } })
        Object.defineProperty(controller, "editorRowsTarget", { get() { return editorRowsTarget } })
        controller.settingsFromEditor = () => JSON.parse(JSON.stringify(currentSettings))
        controller.apply = () => {}

        controller.installDirtyStateTracking()
        controller.markEditorClean()

        if (dirtyElements.length !== 1) {
          throw new Error("dirty-state helper was not inserted next to the status region")
        }

        if (!controller.dirtyStateTarget.hidden || controller.dirtyStateTarget.textContent !== "") {
          throw new Error("dirty-state helper should start hidden after snapshot capture")
        }

        currentSettings = { columns: [{ key: "name", visible: false, order: 10 }], filters: {}, sorts: [] }
        controller.applyFromEditor()

        if (controller.dirtyStateTarget.hidden || controller.dirtyStateTarget.textContent !== "Unsaved changes") {
          throw new Error("dirty-state helper did not show after editor settings changed")
        }

        if (statusTarget.textContent) {
          throw new Error("dirty-state helper should not write to the async status target")
        }

        currentSettings = { columns: [{ key: "name", visible: false, order: 10 }], filters: { name: { operator: "contains", value: "A" } }, sorts: [] }
        controller.updateDirtyStateFromEditor()

        if (controller.dirtyStateTarget.hidden) {
          throw new Error("dirty-state helper should stay visible after unsaved filter changes")
        }

        controller.markEditorClean()

        if (!controller.dirtyStateTarget.hidden || controller.dirtyStateTarget.textContent !== "") {
          throw new Error("dirty-state helper should clear after save or load snapshot refresh")
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
