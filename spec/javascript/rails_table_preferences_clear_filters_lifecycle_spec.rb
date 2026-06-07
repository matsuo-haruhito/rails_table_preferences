require "fileutils"
require "open3"
require "pathname"
require "tmpdir"

RSpec.describe "rails_table_preferences clear filters lifecycle event", type: :javascript do
  def build_controller_sandbox(root, sandbox)
    controller_dir = sandbox.join("rails_table_preferences")
    base_dir = sandbox.join("controllers")
    stimulus_dir = sandbox.join("node_modules", "@hotwired", "stimulus")

    FileUtils.mkdir_p(controller_dir)
    FileUtils.mkdir_p(base_dir)
    FileUtils.mkdir_p(stimulus_dir)

    File.write(sandbox.join("package.json"), JSON.generate(type: "module"))
    File.write(stimulus_dir.join("package.json"), JSON.generate(type: "module", main: "index.js"))
    File.write(stimulus_dir.join("index.js"), <<~JS)
      export class Controller {}
    JS

    controller_source = File.read(root.join("app/javascript/rails_table_preferences/controller.js"))
      .gsub('"../controllers/rails_table_preferences_controller"', '"../controllers/rails_table_preferences_controller.js"')
    File.write(controller_dir.join("controller.js"), controller_source)
    FileUtils.cp(root.join("app/javascript/controllers/rails_table_preferences_controller.js"), base_dir.join("rails_table_preferences_controller.js"))
  end

  it "dispatches applied with a clear-filters-and-sorts action after neutralizing filter and sort settings" do
    root = Pathname.new(__dir__).join("../..").realpath

    Dir.mktmpdir do |dir|
      sandbox = Pathname.new(dir)
      build_controller_sandbox(root, sandbox)

      controller_path = sandbox.join("rails_table_preferences/controller.js").to_s
      script = <<~JS
        import { pathToFileURL } from "node:url"

        const { default: ControllerClass } = await import(pathToFileURL(#{controller_path.inspect}).href)
        const controller = new ControllerClass()
        const events = []
        let applyCount = 0

        controller.dispatch = (name, options = {}) => events.push({ name, detail: options.detail })
        controller.tableKeyValue = "orders"
        controller.nameValue = "default"
        controller.hasPresetNameTarget = false
        controller.closeFilterPanel = () => {}
        controller.apply = () => { applyCount += 1 }
        controller.settingsValue = {
          columns: [{ key: "total", visible: true }],
          filters: { total: { operator: "gt", value: "100" } },
          sorts: [{ key: "total", direction: "desc" }]
        }

        controller.clearFiltersAndSorts({ preventDefault() {} })

        const applied = events.find((event) => event.name === "applied" && event.detail.action === "clear-filters-and-sorts")
        if (!applied) throw new Error("clear filters/sorts applied event was not dispatched")
        if (applyCount !== 1) throw new Error(`expected apply to run once, got ${applyCount}`)
        if (applied.detail.tableKey !== "orders") throw new Error("clear filters/sorts event lost tableKey")
        if (applied.detail.name !== "default") throw new Error("clear filters/sorts event lost preset name")
        if (Object.keys(applied.detail.settings.filters).length !== 0) throw new Error("clear filters/sorts event did not expose empty filters")
        if (!Array.isArray(applied.detail.settings.sorts) || applied.detail.settings.sorts.length !== 0) throw new Error("clear filters/sorts event did not expose empty sorts")
        if (applied.detail.settings.columns[0].visible !== true) throw new Error("clear filters/sorts event should preserve column settings")

        controller.settingsValue = {
          columns: [{ key: "total", visible: true }],
          filters: { total: { operator: "gt", value: "200" } },
          sorts: [{ key: "total", direction: "asc" }]
        }
        controller.busy = true
        const eventCountBeforeBusyClear = events.length
        const applyCountBeforeBusyClear = applyCount

        controller.clearFiltersAndSorts({ preventDefault() {} })

        if (events.length !== eventCountBeforeBusyClear) throw new Error("busy clearFiltersAndSorts dispatched an event")
        if (applyCount !== applyCountBeforeBusyClear) throw new Error("busy clearFiltersAndSorts applied settings")
        if (controller.settingsValue.filters.total.value !== "200") throw new Error("busy clearFiltersAndSorts changed filters")
        if (controller.settingsValue.sorts[0].direction !== "asc") throw new Error("busy clearFiltersAndSorts changed sorts")
      JS

      stdout, stderr, status = Open3.capture3("node", "--input-type=module", stdin_data: script)
      expect(status).to be_success, "Node script failed:\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}"
    end
  end
end
