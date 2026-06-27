# frozen_string_literal: true

require "fileutils"
require "open3"
require "spec_helper"
require "tmpdir"

RSpec.describe "rails_table_preferences package preset default label" do
  let(:repo_root) { File.expand_path("../..", __dir__) }

  def build_controller_sandbox
    Dir.mktmpdir("rails-table-preferences-package-presets") do |tmpdir|
      base_controller_dir = File.join(tmpdir, "app/javascript/controllers")
      package_controller_dir = File.join(tmpdir, "app/javascript/rails_table_preferences")
      stimulus_dir = File.join(tmpdir, "node_modules/@hotwired/stimulus")

      FileUtils.mkdir_p(base_controller_dir)
      FileUtils.mkdir_p(package_controller_dir)
      FileUtils.mkdir_p(stimulus_dir)

      File.write(File.join(tmpdir, "package.json"), "{\n  \"type\": \"module\"\n}\n")
      FileUtils.cp(
        File.join(repo_root, "app/javascript/controllers/rails_table_preferences_controller.js"),
        File.join(base_controller_dir, "rails_table_preferences_controller.js")
      )
      FileUtils.cp(
        File.join(repo_root, "app/javascript/controllers/rails_table_preferences_controller.js"),
        File.join(base_controller_dir, "rails_table_preferences_controller")
      )
      FileUtils.cp(
        File.join(repo_root, "app/javascript/rails_table_preferences/controller.js"),
        File.join(package_controller_dir, "controller.js")
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
      expected package preset default label source check to pass

      stdout:
      #{stdout}

      stderr:
      #{stderr}
    MESSAGE
  end

  it "renders readable default labels without changing preset identity datasets" do
    build_controller_sandbox do |tmpdir|
      script = <<~JS
        const { default: ControllerClass } = await import("./app/javascript/rails_table_preferences/controller.js")

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
        controller.scopeOwnerLabelValue = "個人"
        controller.scopeRoleLabelValue = "ロール"
        controller.scopeOrganizationLabelValue = "組織"
        controller.scopeSharedLabelValue = "共有"

        const sharedOption = controller.buildPresetOption({
          name: "shared-base",
          scope_type: "shared",
          scope_label: "全体",
          scope_key: "global",
          default: true,
          editable: false
        })

        if (sharedOption.textContent !== "shared-base [全体]（既定）") {
          throw new Error(`shared default option did not explain the default state: ${sharedOption.textContent}`)
        }

        if (sharedOption.dataset.default !== "true" || sharedOption.dataset.editable !== "false") {
          throw new Error("shared default option changed default/editable datasets")
        }

        if (sharedOption.dataset.scopeType !== "shared" || sharedOption.dataset.scopeKey !== "global") {
          throw new Error("shared default option changed scope identity datasets")
        }

        const ownerOption = controller.buildPresetOption({
          name: "mine",
          scope_type: "owner",
          default: true,
          editable: true
        })

        if (ownerOption.textContent !== "mine [個人]（既定）") {
          throw new Error(`owner default option should keep scope and readable default label: ${ownerOption.textContent}`)
        }

        const roleOption = controller.buildPresetOption({
          name: "ops",
          scope_type: "role",
          scope_label: "role:operations",
          scope_key: "operations",
          default: false,
          editable: false
        })

        if (roleOption.textContent !== "ops [role:operations]") {
          throw new Error(`non-default scoped option should not gain default copy: ${roleOption.textContent}`)
        }
      JS

      run_node_controller_check(script: script, chdir: tmpdir)
    end
  end
end
