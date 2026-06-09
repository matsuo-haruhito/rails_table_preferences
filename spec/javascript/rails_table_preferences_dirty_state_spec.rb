# frozen_string_literal: true

require "fileutils"
require "open3"
require "spec_helper"
require "tmpdir"

RSpec.describe "rails_table_preferences package dirty-state behavior" do
  let(:repo_root) { File.expand_path("../..", __dir__) }

  def build_entrypoint_sandbox
    Dir.mktmpdir("rails-table-preferences-dirty-state") do |tmpdir|
      package_dir = File.join(tmpdir, "app/javascript/rails_table_preferences")
      controller_dir = File.join(tmpdir, "app/javascript/controllers")
      stimulus_dir = File.join(tmpdir, "node_modules/@hotwired/stimulus")

      FileUtils.mkdir_p(package_dir)
      FileUtils.mkdir_p(controller_dir)
      FileUtils.mkdir_p(stimulus_dir)

      File.write(File.join(tmpdir, "package.json"), "{\n  \"type\": \"module\"\n}\n")
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

      yield tmpdir
    end
  end

  def run_node_entrypoint_check(*paths, script:)
    stdout, stderr, status = Open3.capture3("node", "--input-type=module", "-e", script, *paths)

    expect(status).to be_success, <<~MESSAGE
      expected package dirty-state entrypoint behavior to be stable

      stdout:
      #{stdout}

      stderr:
      #{stderr}
    MESSAGE
  end

  it "keeps dirty-state targets and values package-only" do
    build_entrypoint_sandbox do |tmpdir|
      base_controller_path = File.join(tmpdir, "app/javascript/controllers/rails_table_preferences_controller.js")
      package_controller_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const baseUrl = pathToFileURL(process.argv[1]).href
        const packageUrl = pathToFileURL(process.argv[2]).href
        const { default: BaseController } = await import(baseUrl)
        const { default: PackageController } = await import(packageUrl)
        const baseTargets = BaseController.targets || []
        const packageTargets = PackageController.targets || []

        if (Object.hasOwn(BaseController.values, "dirtyStateLabel")) throw new Error("dirtyStateLabel leaked into copied controller")
        if (!Object.hasOwn(PackageController.values, "dirtyStateLabel")) throw new Error("dirtyStateLabel missing from package controller")
        if (baseTargets.includes("dirtyState")) throw new Error("dirtyState target leaked into copied controller")
        if (!packageTargets.includes("dirtyState")) throw new Error("dirtyState target missing from package controller")
      JS

      run_node_entrypoint_check(base_controller_path, package_controller_path, script:)
    end
  end

  it "tracks unsaved editor changes without using the async status region" do
    build_entrypoint_sandbox do |tmpdir|
      controller_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const dirtyElements = []
        const statusTarget = { parentNode: { insertBefore(element) { dirtyElements.push(element) } } }
        const editorRowsTarget = { addEventListener() {}, removeEventListener() {}, querySelectorAll() { return [] } }
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
        controller.dispatchPreferenceEvent = () => {}

        controller.installDirtyStateTracking()
        controller.markEditorClean()

        if (dirtyElements.length !== 1) throw new Error("dirty-state helper was not inserted next to the status region")
        if (!controller.dirtyStateTarget.hidden || controller.dirtyStateTarget.textContent !== "") throw new Error("dirty-state helper should start hidden")

        currentSettings = { columns: [{ key: "name", visible: false, order: 10 }], filters: {}, sorts: [] }
        controller.applyFromEditor()

        if (controller.dirtyStateTarget.hidden || controller.dirtyStateTarget.textContent !== "Unsaved changes") throw new Error("dirty-state helper did not show")
        if (statusTarget.textContent) throw new Error("dirty-state helper should not write to the async status target")

        controller.markEditorClean()
        if (!controller.dirtyStateTarget.hidden || controller.dirtyStateTarget.textContent !== "") throw new Error("dirty-state helper should clear after snapshot refresh")
      JS

      run_node_entrypoint_check(controller_entrypoint_path, script:)
    end
  end

  it "clears the dirty-state helper after a successful preset delete" do
    build_entrypoint_sandbox do |tmpdir|
      controller_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const controller = new ControllerClass()
        let dirtyStateElement = null
        let currentSettings = { columns: [{ key: "name", visible: true, order: 10 }], filters: {}, sorts: [] }
        let fetchMethod = null

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
        globalThis.fetch = async (_url, options) => {
          fetchMethod = options.method
          return { ok: true, status: 204 }
        }

        controller.element = { appendChild(element) { dirtyStateElement = element }, querySelector() { return null } }
        controller.defaultSettings = { columns: [{ key: "name", visible: true, order: 10 }], filters: {}, sorts: [] }
        controller.settingsValue = JSON.parse(JSON.stringify(currentSettings))
        controller.dirtyStateLabelValue = "Unsaved changes"
        controller.currentPreferenceEditable = true
        controller.nameValue = "custom"
        controller.urlValue = "/preferences/custom"
        Object.defineProperty(controller, "currentPresetName", { get() { return this.nameValue } })
        Object.defineProperty(controller, "csrfToken", { get() { return "token" } })
        Object.defineProperty(controller, "hasDirtyStateTarget", { get() { return dirtyStateElement !== null } })
        Object.defineProperty(controller, "dirtyStateTarget", { get() { return dirtyStateElement } })
        Object.defineProperty(controller, "hasStatusTarget", { get() { return false } })
        Object.defineProperty(controller, "hasEditorRowsTarget", { get() { return true } })
        Object.defineProperty(controller, "editorRowsTarget", { get() { return { addEventListener() {}, removeEventListener() {}, querySelectorAll() { return [] } } } })
        controller.settingsFromEditor = () => JSON.parse(JSON.stringify(currentSettings))
        controller.preferenceUrl = (name) => `/preferences/${name}`
        controller.confirmDeletePreset = () => true
        controller.withPreferenceAction = async (_action, callback) => callback()
        controller.withBusyStatus = async (callback) => callback()
        controller.setPresetNameInput = (name) => { controller.nameValue = name }
        controller.setDefaultPresetInput = () => {}
        controller.closeFilterPanel = () => {}
        controller.apply = () => {}
        controller.syncPresetEditingState = () => {}
        controller.dispatchPreferenceEvent = () => {}
        controller.refreshPresetOptions = async () => {}
        controller.renderEditor = () => {
          currentSettings = JSON.parse(JSON.stringify(controller.settingsValue))
          controller.updateDirtyStateFromEditor()
        }

        controller.installDirtyStateTracking()
        controller.markEditorClean()
        currentSettings = { columns: [{ key: "name", visible: false, order: 10 }], filters: {}, sorts: [] }
        controller.updateDirtyStateFromEditor()

        if (controller.dirtyStateTarget.hidden) throw new Error("dirty-state helper should be visible before delete")

        await controller.deletePreset({ preventDefault() {} })

        if (fetchMethod !== "DELETE") throw new Error("deletePreset did not issue DELETE")
        if (controller.nameValue !== "default" || controller.urlValue !== "/preferences/default") throw new Error("deletePreset did not return to default")
        if (!controller.dirtyStateTarget.hidden || controller.dirtyStateTarget.textContent !== "") throw new Error("dirty-state helper should clear after delete")
      JS

      run_node_entrypoint_check(controller_entrypoint_path, script:)
    end
  end
end
