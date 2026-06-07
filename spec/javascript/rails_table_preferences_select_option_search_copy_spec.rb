# frozen_string_literal: true

require "fileutils"
require "open3"
require "spec_helper"
require "tmpdir"

RSpec.describe "rails_table_preferences select filter option search copy" do
  let(:repo_root) { File.expand_path("../..", __dir__) }

  def build_entrypoint_sandbox
    Dir.mktmpdir("rails-table-preferences-select-option-search-copy") do |tmpdir|
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
      expected select option search copy checks to pass

      stdout:
      #{stdout}

      stderr:
      #{stderr}
    MESSAGE
  end

  it "keeps select option search copy as package-only root values" do
    build_entrypoint_sandbox do |tmpdir|
      base_controller_path = File.join(tmpdir, "app/javascript/controllers/rails_table_preferences_controller.js")
      package_controller_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const baseUrl = pathToFileURL(process.argv[1]).href
        const packageUrl = pathToFileURL(process.argv[2]).href
        const { default: BaseController } = await import(baseUrl)
        const { default: PackageController } = await import(packageUrl)

        for (const key of ["selectFilterOptionSearchLabel", "selectFilterOptionSearchPlaceholder"]) {
          if (Object.hasOwn(BaseController.values, key)) {
            throw new Error(`${key} leaked into the copied controller contract`)
          }

          if (!Object.hasOwn(PackageController.values, key)) {
            throw new Error(`package entrypoint no longer exposes ${key}`)
          }

          if (PackageController.values[key].default !== "候補を絞り込み") {
            throw new Error(`${key} no longer keeps the bundled default copy`)
          }
        }
      JS

      run_node_entrypoint_check(base_controller_path, package_controller_path, script:)
    end
  end

  it "uses controller-root overrides for select option search label and placeholder" do
    build_entrypoint_sandbox do |tmpdir|
      package_controller_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const packageUrl = pathToFileURL(process.argv[1]).href
        const { default: PackageController } = await import(packageUrl)
        const controller = new PackageController()

        controller.filterValueLabelValue = "Value"
        controller.selectFilterOptionSearchLabelValue = "Search choices"
        controller.selectFilterOptionSearchPlaceholderValue = "Type to filter"

        const html = controller.selectFilterOptionSearchHtml([
          "draft", "ready", "queued", "sent", "paid", "refunded", "failed", "archived"
        ])

        if (!html.includes('aria-label="Value: Search choices"')) {
          throw new Error(`override label was not reflected in aria-label: ${html}`)
        }

        if (!html.includes('placeholder="Type to filter"')) {
          throw new Error(`override placeholder was not reflected: ${html}`)
        }
      JS

      run_node_entrypoint_check(package_controller_path, script:)
    end
  end
end
