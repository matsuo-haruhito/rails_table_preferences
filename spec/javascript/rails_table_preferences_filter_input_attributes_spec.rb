# frozen_string_literal: true

require "fileutils"
require "open3"
require "spec_helper"
require "tmpdir"

RSpec.describe "rails_table_preferences filter input attributes" do
  let(:repo_root) { File.expand_path("../..", __dir__) }

  def build_entrypoint_sandbox
    Dir.mktmpdir("rails-table-preferences-filter-input-attributes") do |tmpdir|
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

  it "renders min max and step as escaped browser affordances for number and date filters only" do
    build_entrypoint_sandbox do |tmpdir|
      package_controller_path = File.join(tmpdir, "app/javascript/rails_table_preferences/controller.js")
      script = <<~JS
        import { pathToFileURL } from "node:url"

        globalThis.document = {
          createElement() {
            return {
              _textContent: "",
              set textContent(value) {
                this._textContent = String(value)
              },
              get innerHTML() {
                return this._textContent
                  .replaceAll("&", "&amp;")
                  .replaceAll("<", "&lt;")
                  .replaceAll(">", "&gt;")
                  .replaceAll('"', "&quot;")
                  .replaceAll("'", "&#39;")
              }
            }
          }
        }

        const { default: ControllerClass } = await import(pathToFileURL(process.argv[1]).href)
        const controller = new ControllerClass()
        controller.filterValueLabelValue = "Value"
        controller.filterFromLabelValue = "From"
        controller.filterToLabelValue = "To"

        const numberHtml = controller.filterValueHtml(
          { type: "number", placeholder: "0以上", min: "0", max: "100", step: "0.5" },
          { value: "10" },
          "equals"
        )
        for (const expected of ['type="number"', 'placeholder="0以上"', 'min="0"', 'max="100"', 'step="0.5"']) {
          if (!numberHtml.includes(expected)) throw new Error(`number filter missing ${expected}: ${numberHtml}`)
        }

        const dateHtml = controller.filterValueHtml(
          { type: "date", min: "2026-01-01", max: "2026-12-31", step: "7", from_placeholder: "start", to_placeholder: "end" },
          { from: "2026-02-01", to: "2026-02-28" },
          "between"
        )
        for (const expected of ['type="date"', 'data-field="from"', 'data-field="to"', 'min="2026-01-01"', 'max="2026-12-31"', 'step="7"', 'placeholder="start"', 'placeholder="end"']) {
          if (!dateHtml.includes(expected)) throw new Error(`date range filter missing ${expected}: ${dateHtml}`)
        }

        const escapedHtml = controller.filterValueHtml(
          { type: "number", min: '0" autofocus="true', max: "5 < 10", step: "1 & 2" },
          { value: "1" },
          "equals"
        )
        for (const expected of ['min="0&quot; autofocus=&quot;true"', 'max="5 &lt; 10"', 'step="1 &amp; 2"']) {
          if (!escapedHtml.includes(expected)) throw new Error(`attribute was not escaped as ${expected}: ${escapedHtml}`)
        }

        const textHtml = controller.filterValueHtml(
          { type: "text", placeholder: "keyword", min: "0", max: "100", step: "1" },
          { value: "abc" },
          "contains"
        )
        if (!textHtml.includes('placeholder="keyword"')) throw new Error(`text filter lost placeholder: ${textHtml}`)
        for (const unexpected of ['min="0"', 'max="100"', 'step="1"']) {
          if (textHtml.includes(unexpected)) throw new Error(`text filter leaked ${unexpected}: ${textHtml}`)
        }
      JS

      stdout, stderr, status = Open3.capture3("node", "--input-type=module", "-e", script, package_controller_path)
      expect(status).to be_success, <<~MESSAGE
        expected filter input attribute checks to pass

        stdout:
        #{stdout}

        stderr:
        #{stderr}
      MESSAGE
    end
  end
end
