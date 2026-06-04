# frozen_string_literal: true

require "fileutils"
require "open3"
require "spec_helper"
require "tmpdir"

RSpec.describe "rails_table_preferences scoped preset selector" do
  let(:repo_root) { File.expand_path("../..", __dir__) }

  def build_controller_sandbox
    Dir.mktmpdir("rails-table-preferences-scoped-presets") do |tmpdir|
      controller_dir = File.join(tmpdir, "app/javascript/controllers")
      stimulus_dir = File.join(tmpdir, "node_modules/@hotwired/stimulus")

      FileUtils.mkdir_p(controller_dir)
      FileUtils.mkdir_p(stimulus_dir)

      File.write(File.join(tmpdir, "package.json"), "{\n  \"type\": \"module\"\n}\n")
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

  def run_node_controller_check(script:, chdir:)
    stdout, stderr, status = Open3.capture3("node", "--input-type=module", "-e", script, chdir: chdir)

    expect(status).to be_success, <<~MESSAGE
      expected scoped preset selector source check to pass

      stdout:
      #{stdout}

      stderr:
      #{stderr}
    MESSAGE
  end

  it "renders native optgroups for multi-scope presets while keeping single-scope lists flat" do
    build_controller_sandbox do |tmpdir|
      script = <<~JS
        const { default: ControllerClass } = await import("./app/javascript/controllers/rails_table_preferences_controller.js")

        const createElement = (tagName) => ({
          tagName: tagName.toUpperCase(),
          children: [],
          dataset: {},
          textContent: "",
          value: "",
          label: "",
          appendChild(child) { this.children.push(child); return child },
          querySelectorAll() { return [] },
          get innerHTML() { return this._innerHTML || "" },
          set innerHTML(value) { this._innerHTML = value; this.children = [] }
        })

        globalThis.document = { createElement }

        const controller = new ControllerClass()
        const select = createElement("select")
        select.innerHTML = "stale"
        controller.presetSelectTarget = select
        Object.defineProperty(controller, "currentPresetName", { value: "mine" })
        controller.scopeOwnerLabelValue = "個人"
        controller.scopeRoleLabelValue = "ロール"
        controller.scopeOrganizationLabelValue = "組織"
        controller.scopeSharedLabelValue = "共有"
        controller.syncDeletePresetButtonContext = () => {}
        Object.defineProperty(controller, "hasPresetSelectTarget", { value: true })

        controller.presets = [
          { name: "shared-base", scope_type: "shared", scope_label: "全体", default: true, editable: false },
          { name: "mine", scope_type: "owner", default: false, editable: true },
          { name: "ops", scope_type: "role", scope_label: "role:operations", scope_key: "operations", default: false, editable: false },
          { name: "tokyo", scope_type: "organization", scope_label: "organization:tokyo", scope_key: "tokyo", default: false, editable: false },
          { name: "external", scope_type: "tenant", scope_label: "tenant:external", scope_key: "external", default: false, editable: false }
        ]

        controller.renderPresetOptions()

        const groupLabels = select.children.map((child) => child.label)
        if (JSON.stringify(groupLabels) !== JSON.stringify(["個人", "ロール", "組織", "共有", "tenant"])) {
          throw new Error(`unexpected optgroup labels: ${JSON.stringify(groupLabels)}`)
        }

        const optionOrder = select.children.flatMap((group) => group.children.map((option) => option.value))
        if (JSON.stringify(optionOrder) !== JSON.stringify(["mine", "ops", "tokyo", "shared-base", "external"])) {
          throw new Error(`unexpected option order: ${JSON.stringify(optionOrder)}`)
        }

        const roleOption = select.children[1].children[0]
        if (roleOption.textContent !== "ops [role:operations]") {
          throw new Error(`role option text lost scope context: ${roleOption.textContent}`)
        }

        if (roleOption.dataset.scopeType !== "role" || roleOption.dataset.scopeKey !== "operations") {
          throw new Error("role option lost keyboard-selectable scope dataset")
        }

        const sharedOption = select.children[3].children[0]
        if (sharedOption.textContent !== "shared-base [全体] *") {
          throw new Error(`shared option lost default mark: ${sharedOption.textContent}`)
        }

        if (select.value !== "mine") {
          throw new Error(`select value did not keep current preset: ${select.value}`)
        }

        controller.presets = [
          { name: "mine", scope_type: "owner", default: false, editable: true },
          { name: "alternate", scope_type: "owner", default: false, editable: true }
        ]
        controller.renderPresetOptions()

        if (select.children.some((child) => child.tagName === "OPTGROUP")) {
          throw new Error("single-scope owner presets should remain a flat native select")
        }

        if (JSON.stringify(select.children.map((option) => option.value)) !== JSON.stringify(["mine", "alternate"])) {
          throw new Error("single-scope option order changed")
        }
      JS

      run_node_controller_check(script: script, chdir: tmpdir)
    end
  end
end
