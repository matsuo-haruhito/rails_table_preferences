# frozen_string_literal: true

require "fileutils"
require "open3"
require "spec_helper"
require "tmpdir"

RSpec.describe "rails_table_preferences editor search count cue" do
  let(:repo_root) { File.expand_path("../..", __dir__) }

  def build_entrypoint_sandbox
    Dir.mktmpdir("rails-table-preferences-editor-search-count") do |tmpdir|
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
      File.write(
        File.join(package_dir, "preset_select_recovery.js"),
        File.read(File.join(repo_root, "app/javascript/rails_table_preferences/preset_select_recovery.js"))
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

  def run_node_check(path, script:)
    stdout, stderr, status = Open3.capture3("node", "--input-type=module", "-e", script, path)

    expect(status).to be_success, <<~MESSAGE
      expected editor search count cue behavior to remain stable

      stdout:
      #{stdout}

      stderr:
      #{stderr}
    MESSAGE
  end

  it "shows a result count only while a query has matching editor rows" do
    build_entrypoint_sandbox do |tmpdir|
      entrypoint_path = File.join(tmpdir, "app/javascript/rails_table_preferences/preset_select_recovery.js")

      script = <<~JS
        import { pathToFileURL } from "node:url"

        const datasetKey = (name) => name.replace(/^data-/, "").replace(/-([a-z])/g, (_, letter) => letter.toUpperCase())
        const attributeSelector = (selector) => {
          if (!selector.startsWith("[") || !selector.endsWith("]")) return null
          const body = selector.slice(1, -1)
          const separator = body.indexOf("=")
          if (separator < 0) return { name: body.trim(), expected: undefined }
          const name = body.slice(0, separator).trim()
          let expected = body.slice(separator + 1).trim()
          const quoted = (expected.startsWith('"') && expected.endsWith('"')) || (expected.startsWith("'") && expected.endsWith("'"))
          if (quoted) expected = expected.slice(1, -1)
          return { name, expected }
        }

        class FakeElement {
          constructor(tagName = "div") {
            this.tagName = tagName.toUpperCase()
            this.children = []
            this.parentNode = null
            this.dataset = {}
            this.attributes = {}
            this.hidden = false
            this.textContent = ""
            this.value = ""
            this.className = ""
          }

          append(...nodes) { nodes.forEach((node) => this.appendChild(node)) }

          appendChild(node) {
            if (node.parentNode) node.parentNode.removeChild(node)
            node.parentNode = this
            this.children.push(node)
            return node
          }

          removeChild(node) {
            const index = this.children.indexOf(node)
            if (index >= 0) this.children.splice(index, 1)
            node.parentNode = null
            return node
          }

          setAttribute(name, value) {
            const stringValue = String(value)
            this.attributes[name] = stringValue
            if (name.startsWith("data-")) this.dataset[datasetKey(name)] = stringValue
          }

          matches(selector) {
            const attribute = attributeSelector(selector)
            if (!attribute) return false
            const { name, expected } = attribute
            const actual = name.startsWith("data-") ? this.dataset[datasetKey(name)] : this.attributes[name]
            if (expected === undefined) return actual !== undefined
            return actual === expected
          }

          querySelector(selector) { return this.querySelectorAll(selector)[0] || null }

          querySelectorAll(selector) {
            const results = []
            const visit = (node) => {
              node.children.forEach((child) => {
                if (child.matches(selector)) results.push(child)
                visit(child)
              })
            }
            visit(this)
            return results
          }
        }

        const entrypointUrl = pathToFileURL(process.argv[1]).href
        const { default: ControllerClass } = await import(entrypointUrl)
        const controller = new ControllerClass()
        const root = new FakeElement("section")
        const searchControl = new FakeElement("div")
        const searchInput = new FakeElement("input")
        const countMessage = new FakeElement("p")
        const emptyMessage = new FakeElement("p")

        searchControl.dataset.railsTablePreferencesEditorSearch = "true"
        searchInput.dataset.railsTablePreferencesEditorSearchInput = "true"
        countMessage.dataset.railsTablePreferencesEditorSearchCount = "true"
        emptyMessage.dataset.railsTablePreferencesEditorSearchEmpty = "true"
        searchControl.append(searchInput, countMessage, emptyMessage)
        root.append(searchControl)

        const row = (key, searchText) => {
          const element = new FakeElement("div")
          element.dataset.railsTablePreferencesColumnKey = key
          element.dataset.railsTablePreferencesEditorSearchText = searchText
          return element
        }
        const account = row("account", "account customer")
        const shipping = row("shipping", "shipping address")
        const total = row("total", "account total")
        const rows = [account, shipping, total]

        Object.defineProperty(controller, "element", { value: root })
        Object.defineProperty(controller, "hasEditorRowsTarget", { value: true })
        Object.defineProperty(controller, "editorRows", { value: rows })
        controller.busy = false
        controller.editorSearchResultCountLabelValue = "表示中の列: {visible} / {total}"

        searchInput.value = "account"
        controller.syncEditorSearchResults()

        if (countMessage.hidden) throw new Error("matching query did not show the result count cue")
        if (countMessage.textContent !== "表示中の列: 2 / 3") throw new Error(`unexpected result count text: ${countMessage.textContent}`)
        if (emptyMessage.hidden !== true) throw new Error("no-results message appeared while matches existed")
        if (account.hidden || !shipping.hidden || total.hidden) throw new Error("query did not preserve the expected row visibility")

        searchInput.value = ""
        controller.syncEditorSearchResults()

        if (!countMessage.hidden) throw new Error("empty query did not hide the result count cue")
        if (countMessage.textContent !== "") throw new Error("empty query left stale result count text")
        if (rows.some((candidate) => candidate.hidden)) throw new Error("empty query did not restore every row")

        searchInput.value = "missing"
        controller.syncEditorSearchResults()

        if (!countMessage.hidden) throw new Error("no-results query should leave the count cue hidden")
        if (countMessage.textContent !== "") throw new Error("no-results query left stale result count text")
        if (emptyMessage.hidden) throw new Error("no-results query did not show the existing empty message")
      JS

      run_node_check(entrypoint_path, script:)
    end
  end
end
