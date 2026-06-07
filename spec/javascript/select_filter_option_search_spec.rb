# frozen_string_literal: true

require "fileutils"
require "open3"
require "spec_helper"
require "tmpdir"

RSpec.describe "select filter option search" do
  let(:repo_root) { File.expand_path("../..", __dir__) }

  def build_controller_sandbox
    Dir.mktmpdir("rails-table-preferences-select-filter") do |tmpdir|
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

  def run_node_check(script:, chdir:)
    stdout, stderr, status = Open3.capture3("node", "--input-type=module", "-e", script, chdir: chdir)

    expect(status).to be_success, <<~MESSAGE
      expected select filter option search behavior to stay stable

      stdout:
      #{stdout}

      stderr:
      #{stderr}
    MESSAGE
  end

  it "keeps selected static select options visible while hiding only unselected non-matches" do
    build_controller_sandbox do |tmpdir|
      controller_entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const controllerUrl = pathToFileURL("#{controller_entrypoint_path}").href
        const { default: ControllerClass } = await import(controllerUrl)
        const controller = new ControllerClass()
        const option = ({ text, value, selected = false }) => ({ textContent: text, value, selected, hidden: false })

        const selectedNonMatch = option({ text: "Pending", value: "pending", selected: true })
        const selectedValueMatch = option({ text: "Needs review", value: "review", selected: true })
        const unselectedMatch = option({ text: "Archived", value: "archived" })
        const unselectedNonMatch = option({ text: "Closed", value: "closed" })
        const select = { options: [selectedNonMatch, selectedValueMatch, unselectedMatch, unselectedNonMatch] }
        const input = { value: "archived" }

        controller.filterSelectOptionsBySearch(input, select)

        if (selectedNonMatch.hidden) {
          throw new Error("selected option that does not match the query was hidden")
        }

        if (selectedValueMatch.hidden) {
          throw new Error("selected option with a non-matching label was hidden")
        }

        if (unselectedMatch.hidden) {
          throw new Error("unselected option matching the query was hidden")
        }

        if (!unselectedNonMatch.hidden) {
          throw new Error("unselected option that does not match the query stayed visible")
        }

        input.value = "needs"
        controller.filterSelectOptionsBySearch(input, select)

        if (selectedValueMatch.hidden) {
          throw new Error("selected option matching by label was hidden after another query")
        }

        selectedNonMatch.selected = false
        input.value = "archived"
        controller.filterSelectOptionsBySearch(input, select)

        if (!selectedNonMatch.hidden) {
          throw new Error("formerly selected non-match stayed visible after selection changed")
        }
      JS

      run_node_check(script: script, chdir: tmpdir)
    end
  end
end
