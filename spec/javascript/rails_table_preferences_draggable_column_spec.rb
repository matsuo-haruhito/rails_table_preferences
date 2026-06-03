# frozen_string_literal: true

require "fileutils"
require "open3"
require "spec_helper"
require "tmpdir"

RSpec.describe "rails_table_preferences draggable column metadata" do
  let(:repo_root) { File.expand_path("../..", __dir__) }

  def build_controller_sandbox
    Dir.mktmpdir("rails-table-preferences-draggable-columns") do |tmpdir|
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

  def run_node_check(controller_path, script)
    stdout, stderr, status = Open3.capture3("node", "--input-type=module", "-e", script, controller_path)

    expect(status).to be_success, <<~MESSAGE
      expected draggable column controller check to pass

      stdout:
      #{stdout}

      stderr:
      #{stderr}
    MESSAGE
  end

  it "does not install table header drag handlers for draggable false columns" do
    build_controller_sandbox do |controller_path|
      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const cell = (key) => ({
          draggable: undefined,
          dataset: { railsTablePreferencesColumnKey: key },
          classNames: [],
          listeners: [],
          classList: { add(name) { this.owner.classNames.push(name) } },
          addEventListener(name) { this.listeners.push(name) }
        })

        const optOutCell = cell("help_link")
        const normalCell = cell("order_no")
        optOutCell.classList.owner = optOutCell
        normalCell.classList.owner = normalCell

        const controller = new ControllerClass()
        Object.defineProperty(controller, "headerCells", { value: [optOutCell, normalCell] })
        Object.defineProperty(controller, "columnsValue", { value: [
          { key: "help_link", draggable: false },
          { key: "order_no" }
        ] })

        controller.installTableColumnDragHandles()

        if (optOutCell.draggable !== false) throw new Error("opt-out header was not marked non-draggable")
        if (optOutCell.dataset.railsTablePreferencesTableDragDisabled !== "true") throw new Error("opt-out header was not marked drag disabled")
        if (optOutCell.dataset.railsTablePreferencesTableDragInstalled === "true") throw new Error("opt-out header installed drag handlers")
        if (optOutCell.classNames.includes("rails-table-preferences-table-column-draggable")) throw new Error("opt-out header received drag styling")
        if (optOutCell.listeners.length !== 0) throw new Error("opt-out header received drag listeners")

        if (normalCell.draggable !== true) throw new Error("normal header was not marked draggable")
        if (normalCell.dataset.railsTablePreferencesTableDragInstalled !== "true") throw new Error("normal header did not install drag handlers")
        if (!normalCell.classNames.includes("rails-table-preferences-table-column-draggable")) throw new Error("normal header did not receive drag styling")
        if (!normalCell.listeners.includes("dragstart")) throw new Error("normal header did not receive dragstart listener")
      JS

      run_node_check(controller_path, script)
    end
  end

  it "keeps current draggable metadata authoritative when merging saved settings" do
    build_controller_sandbox do |controller_path|
      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(controllerUrl)
        const controller = new ControllerClass()
        Object.defineProperty(controller, "columnsValue", { value: [
          { key: "help_link", draggable: false },
          { key: "order_no" }
        ] })

        const merged = controller.mergeSettings(
          { columns: [
            { key: "help_link", label: "Help", draggable: false },
            { key: "order_no", label: "Order no" }
          ], filters: {}, sorts: [] },
          { columns: [
            { key: "help_link", order: 30, draggable: true },
            { key: "order_no", order: 10, draggable: false }
          ], filters: {}, sorts: [] }
        )

        const helpLink = merged.columns.find((column) => column.key === "help_link")
        const orderNo = merged.columns.find((column) => column.key === "order_no")

        if (helpLink.draggable !== false) throw new Error("current opt-out metadata was not preserved")
        if (orderNo.draggable !== undefined) throw new Error("saved draggable metadata leaked into a current default column")
      JS

      run_node_check(controller_path, script)
    end
  end
end
