# frozen_string_literal: true

require "fileutils"
require "open3"
require "spec_helper"
require "tmpdir"

RSpec.describe "rails_table_preferences package status state hook" do
  let(:repo_root) { File.expand_path("../..", __dir__) }

  def build_entrypoint_sandbox
    Dir.mktmpdir("rails-table-preferences-status-state") do |tmpdir|
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

  def run_node_check(*paths, script:)
    stdout, stderr, status = Open3.capture3("node", "--input-type=module", "-e", script, *paths)

    expect(status).to be_success, <<~MESSAGE
      expected package status state hook check to pass

      stdout:
      #{stdout}

      stderr:
      #{stderr}
    MESSAGE
  end

  it "exposes busy success error and idle on the package status target only" do
    build_entrypoint_sandbox do |tmpdir|
      package_controller_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")
      base_controller_path = File.join(tmpdir, "app/javascript/controllers/rails_table_preferences_controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const packageUrl = pathToFileURL(process.argv[1]).href
        const baseUrl = pathToFileURL(process.argv[2]).href
        const { default: ControllerClass } = await import(packageUrl)
        const { default: BaseController } = await import(baseUrl)

        const statusTarget = {
          textContent: "",
          attributes: {},
          setAttribute(name, value) { this.attributes[name] = String(value) },
          getAttribute(name) { return this.attributes[name] }
        }

        const controller = new ControllerClass()
        Object.defineProperty(controller, "hasStatusTarget", { value: true })
        Object.defineProperty(controller, "statusTarget", { value: statusTarget })
        controller.tableKeyValue = "orders"
        controller.nameValue = "default"
        controller.settingsValue = { columns: [], filters: {}, sorts: [] }

        controller.setStatus("Loading", "busy")
        if (controller.statusState !== "busy") throw new Error("busy state was not stored")
        if (statusTarget.textContent !== "Loading") throw new Error("status text was not delegated to the base controller")
        if (statusTarget.getAttribute("data-rails-table-preferences-status-state") !== "busy") throw new Error("busy state hook was not exposed")

        controller.setStatus("Saved", "success")
        if (statusTarget.getAttribute("data-rails-table-preferences-status-state") !== "success") throw new Error("success state hook was not exposed")

        controller.setStatus("")
        if (controller.statusState !== "idle") throw new Error("empty message did not reset statusState to idle")
        if (statusTarget.textContent !== "") throw new Error("empty message did not clear status text")
        if (statusTarget.getAttribute("data-rails-table-preferences-status-state") !== "idle") throw new Error("idle state hook was not restored")

        const errors = []
        const previousConsoleError = console.error
        console.error = (error) => errors.push(error)
        controller.dispatch = () => {}
        controller.currentPreferenceAction = "save"
        controller.operationFailedStatusLabelValue = "Operation failed"
        controller.handleOperationError(new Error("boom"), "Save failed")
        console.error = previousConsoleError

        if (errors.length !== 1) throw new Error("base error logging was not preserved")
        if (controller.statusState !== "error") throw new Error("error state was not stored")
        if (statusTarget.textContent !== "Save failed") throw new Error("error text was not delegated to the base controller")
        if (statusTarget.getAttribute("data-rails-table-preferences-status-state") !== "error") throw new Error("error state hook was not exposed")

        const noStatusTargetController = new ControllerClass()
        Object.defineProperty(noStatusTargetController, "hasStatusTarget", { value: false })
        noStatusTargetController.setStatus("Loading", "busy")
        if (noStatusTargetController.statusState !== "busy") throw new Error("statusState should update even when the target is absent")

        if (BaseController.prototype.syncStatusStateHook) {
          throw new Error("status state hook leaked into the copied controller")
        }
      JS

      run_node_check(package_controller_path, base_controller_path, script:)
    end
  end

  it "keeps the copied controller source free of the package-only status state data hook" do
    base_source = File.read(File.join(repo_root, "app/javascript/controllers/rails_table_preferences_controller.js"))

    expect(base_source).not_to include("data-rails-table-preferences-status-state")
  end
end
