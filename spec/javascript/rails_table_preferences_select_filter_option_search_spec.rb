# frozen_string_literal: true

require "fileutils"
require "open3"
require "spec_helper"
require "tmpdir"

RSpec.describe "rails_table_preferences select filter option search" do
  let(:repo_root) { File.expand_path("../..", __dir__) }

  def build_controller_sandbox
    Dir.mktmpdir("rails-table-preferences-select-filter-search") do |tmpdir|
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

      yield File.join(package_dir, "controller.js")
    end
  end

  def run_node_controller_check(controller_path, script)
    stdout, stderr, status = Open3.capture3("node", "--input-type=module", "-e", script, controller_path)

    expect(status).to be_success, <<~MESSAGE
      expected select filter option search entrypoint behavior to remain stable

      stdout:
      #{stdout}

      stderr:
      #{stderr}
    MESSAGE
  end

  it "renders a search field only for long static select option lists" do
    build_controller_sandbox do |controller_path|
      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const controller = new ControllerClass()
        controller.filterValueLabelValue = "値"
        controller.escapeHtml = (value) => String(value ?? "")
          .replaceAll("&", "&amp;")
          .replaceAll("<", "&lt;")
          .replaceAll(">", "&gt;")
          .replaceAll('"', "&quot;")

        const longOptions = [
          { value: "pending", label: "未出荷" },
          { value: "shipped", label: "出荷済" },
          { value: "hold", label: "保留" },
          { value: "cancelled", label: "キャンセル" },
          { value: "backorder", label: "入荷待ち" },
          { value: "returned", label: "返品" },
          { value: "review", label: "確認中" },
          { value: "archived", label: "アーカイブ" }
        ]

        const longHtml = controller.filterValueHtml(
          { type: "select", options: longOptions },
          { values: ["hold"] },
          "in"
        )

        if (!longHtml.includes('type="search"')) throw new Error("long select options did not render an option search input")
        if (!longHtml.includes('data-field="option-search"')) throw new Error("option search input lost its data-field")
        if (!longHtml.includes('aria-label="値: 候補を絞り込み"')) throw new Error("option search input lost its accessible label")
        if (!longHtml.includes('value="hold" selected')) throw new Error("selected option value was not preserved")
        if (!longHtml.includes('>保留</option>')) throw new Error("option label was not preserved")

        const shortHtml = controller.filterValueHtml(
          { type: "select", options: longOptions.slice(0, 7) },
          { values: [] },
          "in"
        )

        if (shortHtml.includes('data-field="option-search"')) throw new Error("short select options should not render an option search input")
      JS

      run_node_controller_check(controller_path, script)
    end
  end

  it "filters unmatched options while keeping selected options visible" do
    build_controller_sandbox do |controller_path|
      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const controller = new ControllerClass()
        const input = { value: "ship" }
        const options = [
          { textContent: "Pending", value: "pending", selected: false, hidden: false },
          { textContent: "Shipped", value: "shipped", selected: false, hidden: false },
          { textContent: "Hold", value: "hold", selected: true, hidden: false }
        ]
        const select = { options }

        controller.filterSelectOptionsBySearch(input, select)

        if (options[0].hidden !== true) throw new Error("unmatched unselected option stayed visible")
        if (options[1].hidden !== false) throw new Error("matching option was hidden")
        if (options[2].hidden !== false) throw new Error("selected option should remain visible even when it does not match")

        input.value = ""
        controller.filterSelectOptionsBySearch(input, select)

        if (options.some((option) => option.hidden)) throw new Error("empty search should show all options")
      JS

      run_node_controller_check(controller_path, script)
    end
  end

  it "installs option search listeners only once per input" do
    build_controller_sandbox do |controller_path|
      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const controller = new ControllerClass()
        const input = {
          dataset: {},
          value: "",
          listeners: [],
          addEventListener(type) { this.listeners.push(type) }
        }
        const select = {
          options: [],
          listeners: [],
          addEventListener(type) { this.listeners.push(type) }
        }
        const panel = {
          querySelector(selector) {
            if (selector === "[data-field='option-search']") return input
            if (selector === "[data-field='values']") return select
            return null
          }
        }
        let filterCalls = 0
        controller.filterSelectOptionsBySearch = () => { filterCalls += 1 }

        controller.installSelectFilterOptionSearch(panel)
        controller.installSelectFilterOptionSearch(panel)

        if (input.listeners.length !== 1 || input.listeners[0] !== "input") throw new Error("option search input listener was not installed exactly once")
        if (select.listeners.length !== 1 || select.listeners[0] !== "change") throw new Error("select change listener was not installed exactly once")
        if (filterCalls !== 1) throw new Error("initial option search sync should run exactly once")
      JS

      run_node_controller_check(controller_path, script)
    end
  end
end
