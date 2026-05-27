# frozen_string_literal: true

require "spec_helper"

class RailsTablePreferencesBusyStateSystemSmokeOrdersController < ApplicationController
  helper RailsTablePreferences::TablePreferencesHelper
  include RailsTablePreferences::Controller
  include RailsTablePreferences::TablePreferencesHelper

  DEMO_TABLE_KEY = :rails_table_preferences_busy_state_system_smoke_orders

  CONTROLLER_SOURCE = begin
    File.read(File.expand_path("../../app/javascript/controllers/rails_table_preferences_controller.js", __dir__))
      .sub("import { Controller } from \"@hotwired/stimulus\"\n\n", "")
      .sub("export default class extends Controller {", "class RailsTablePreferencesController extends Controller {")
  end

  BROWSER_SMOKE_SCRIPT = <<~JS
    (() => {
      const controllerSource = #{CONTROLLER_SOURCE.dump};
      const STORAGE_KEY = "rails-table-preferences-busy-state-system-smoke";

      class Controller {}

      function capitalize(value) {
        return value.charAt(0).toUpperCase() + value.slice(1)
      }

      function camelToKebab(value) {
        return value.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase()
      }

      function deepCopy(value) {
        if (Array.isArray(value)) return value.map((item) => deepCopy(item))
        if (value && typeof value === "object") {
          return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, deepCopy(item)]))
        }
        return value
      }

      function descriptorType(descriptor) {
        return descriptor && typeof descriptor === "object" && descriptor.type ? descriptor.type : descriptor
      }

      function descriptorDefault(descriptor) {
        return descriptor && typeof descriptor === "object" && Object.prototype.hasOwnProperty.call(descriptor, "default") ? descriptor.default : undefined
      }

      function parseValue(raw, descriptor) {
        const type = descriptorType(descriptor)
        if (type === Array) return raw ? JSON.parse(raw) : descriptorDefault(descriptor) || []
        if (type === Object) return raw ? JSON.parse(raw) : descriptorDefault(descriptor) || {}
        if (type === Number) return raw == null || raw === "" ? descriptorDefault(descriptor) ?? 0 : Number(raw)
        if (type === Boolean) return raw === "true"
        if (raw == null || raw === "") return descriptorDefault(descriptor) ?? ""
        return raw
      }

      function installTargetAccessors(controller, klass) {
        ;(klass.targets || []).forEach((name) => {
          const selector = `[data-rails-table-preferences-target~="${name}"]`
          Object.defineProperty(controller, `${name}Target`, { get() { return controller.element.querySelector(selector) } })
          Object.defineProperty(controller, `${name}Targets`, { get() { return Array.from(controller.element.querySelectorAll(selector)) } })
          Object.defineProperty(controller, `has${capitalize(name)}Target`, { get() { return controller.element.querySelector(selector) !== null } })
        })
      }

      function installValueAccessors(controller, klass) {
        controller.__stimulusValues = {}
        Object.entries(klass.values || {}).forEach(([name, descriptor]) => {
          const attributeName = `data-rails-table-preferences-${camelToKebab(name)}-value`
          controller.__stimulusValues[name] = parseValue(controller.element.getAttribute(attributeName), descriptor)
          Object.defineProperty(controller, `${name}Value`, {
            get() { return controller.__stimulusValues[name] },
            set(value) { controller.__stimulusValues[name] = value }
          })
        })
      }

      function bindActions(controller) {
        controller.element.querySelectorAll("[data-action]").forEach((element) => {
          element.getAttribute("data-action").split(/\s+/).filter(Boolean).forEach((token) => {
            const parts = token.includes("->") ? token.split("->") : ["click", token]
            const eventName = parts[0]
            const actionName = parts[1]
            if (!actionName || !actionName.startsWith("rails-table-preferences#")) return
            const methodName = actionName.split("#")[1]
            if (typeof controller[methodName] !== "function") return
            element.addEventListener(eventName, (event) => controller[methodName](event))
          })
        })
      }

      function createDeferred() {
        let resolve
        let reject
        const promise = new Promise((res, rej) => {
          resolve = res
          reject = rej
        })
        return { promise, resolve, reject }
      }

      function readStoredPreference(fallbackSettings) {
        try {
          const raw = window.sessionStorage.getItem(STORAGE_KEY)
          if (raw) {
            const parsed = JSON.parse(raw)
            if (parsed && typeof parsed === "object") return parsed
          }
        } catch (_error) {
        }

        return {
          name: "default",
          default: false,
          editable: true,
          settings: deepCopy(fallbackSettings || {})
        }
      }

      function writeStoredPreference(preference) {
        try {
          window.sessionStorage.setItem(STORAGE_KEY, JSON.stringify(preference))
        } catch (_error) {
        }
        return preference
      }

      const fetchControl = {
        mode: null,
        pending: null,
        failNextSave() {
          this.mode = "fail-next-save"
        },
        releaseFailure() {
          if (!this.pending) return false
          const pending = this.pending
          this.pending = null
          this.mode = null
          pending.reject(new Error("Simulated save failure"))
          return true
        }
      }

      function collectionPayload(preference) {
        return {
          preferences: [{
            name: preference.name || "default",
            default: preference.default === true,
            editable: preference.editable !== false
          }]
        }
      }

      function preferencePayload(preference) {
        return {
          name: preference.name || "default",
          default: preference.default === true,
          editable: preference.editable !== false,
          settings: deepCopy(preference.settings || {})
        }
      }

      function installFetchStub(initialSettings) {
        window.fetch = async function(url, options = {}) {
          const method = String(options.method || "GET").toUpperCase()
          const path = new URL(url, window.location.origin).pathname
          const storedPreference = readStoredPreference(initialSettings)

          if (method === "GET") {
            const payload = /\/preferences\/[^/]+\/[^/]+$/.test(path) ? preferencePayload(storedPreference) : collectionPayload(storedPreference)
            return {
              ok: true,
              status: 200,
              json: async () => payload
            }
          }

          if (method === "DELETE") {
            const resetPreference = writeStoredPreference({
              name: "default",
              default: false,
              editable: true,
              settings: deepCopy(initialSettings || {})
            })
            return {
              ok: true,
              status: 200,
              json: async () => preferencePayload(resetPreference)
            }
          }

          if (method === "PATCH" && fetchControl.mode === "fail-next-save") {
            const deferred = createDeferred()
            fetchControl.pending = deferred
            return deferred.promise
          }

          const persistedPreference = writeStoredPreference({
            name: window.__rtpController.currentPresetName,
            default: window.__rtpController.defaultPresetChecked,
            editable: true,
            settings: deepCopy(window.__rtpController.settingsValue)
          })

          return {
            ok: true,
            status: 200,
            json: async () => preferencePayload(persistedPreference)
          }
        }
      }

      function mountController() {
        const root = document.querySelector('[data-controller~="rails-table-preferences"]')
        if (!root) return

        const initialSettings = JSON.parse(root.getAttribute("data-rails-table-preferences-settings-value") || "{}")
        const storedPreference = readStoredPreference(initialSettings)

        installFetchStub(initialSettings)

        const factory = new Function(`${controllerSource}; return RailsTablePreferencesController;`)
        const RailsTablePreferencesController = factory()
        const controller = new RailsTablePreferencesController()
        controller.element = root
        controller.identifier = "rails-table-preferences"
        controller.dispatch = function() {}

        installTargetAccessors(controller, RailsTablePreferencesController)
        installValueAccessors(controller, RailsTablePreferencesController)
        controller.__stimulusValues.settings = deepCopy(storedPreference.settings || initialSettings)
        controller.__stimulusValues.name = storedPreference.name || controller.__stimulusValues.name
        controller.__stimulusValues.url = `${controller.collectionUrlValue}/${encodeURIComponent(controller.__stimulusValues.name || "default")}`
        bindActions(controller)
        controller.connect()
        window.__rtpController = controller
        window.__rtpFetchControl = fetchControl
        document.body.dataset.rtpSmokeReady = "true"
      }

      if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", mountController, { once: true })
      } else {
        mountController()
      }
    })();
  JS

  TEMPLATE = <<~ERB
    <h1>Busy state smoke</h1>

    <%= table_preferences_editor(
      table_key: DEMO_TABLE_KEY,
      settings: @table_preference_settings,
      columns: @table_columns,
      title: "busy state smoke"
    ) %>

    <%= table_preferences_table_tag(
      table_key: DEMO_TABLE_KEY,
      settings: @table_preference_settings,
      columns: @table_columns,
      class: "table"
    ) do %>
      <thead>
        <tr>
          <th data-rails-table-preferences-column-key="order_no">受注番号</th>
          <th data-rails-table-preferences-column-key="memo">備考</th>
        </tr>
      </thead>
      <tbody>
        <% @orders.each do |order| %>
          <tr>
            <td data-rails-table-preferences-column-key="order_no"><%= order[:order_no] %></td>
            <td data-rails-table-preferences-column-key="memo"><%= order[:memo] %></td>
          </tr>
        <% end %>
      </tbody>
    <% end %>

    <script><%= raw self.class::BROWSER_SMOKE_SCRIPT %></script>
  ERB

  def index
    @table_columns = table_columns
    @table_preference_settings = rails_table_preference_settings(table_key: DEMO_TABLE_KEY)
    @orders = demo_orders
    render inline: TEMPLATE, type: :erb
  end

  private

  def table_columns
    [
      table_preferences_column(:order_no, label: "受注番号", default_width: 120),
      table_preferences_column(:memo, label: "備考", default_width: 260)
    ]
  end

  def demo_orders
    [
      { order_no: "A001", memo: "busy state failure recovery" }
    ]
  end
end

Rails.application.routes.disable_clear_and_finalize = true
Rails.application.routes.append do
  get "/rails_table_preferences_system_smoke/busy_failure", to: "rails_table_preferences_busy_state_system_smoke_orders#index"
end
Rails.application.reload_routes!

RSpec.describe "rails_table_preferences busy state browser smoke", type: :system, js: true do
  def visit_demo_smoke
    visit "/rails_table_preferences_system_smoke/busy_failure"
    expect(page.has_selector?("body[data-rtp-smoke-ready='true']")).to eq(true)
  end

  def bundled_async_controls_disabled?
    page.evaluate_script(<<~JS)
      (() => {
        const selector = [
          "select[data-rails-table-preferences-target='presetSelect']",
          "input[data-rails-table-preferences-target='presetName']",
          "input[data-rails-table-preferences-target='defaultPreset']",
          ".rails-table-preferences-editor__actions button"
        ].join(", ")
        const controls = Array.from(document.querySelectorAll(selector))
        return controls.length > 0 && controls.every((control) => control.disabled)
      })()
    JS
  end

  it "disables preset controls while save is in flight and recovers after a failed request" do
    visit_demo_smoke

    row = find(".rails-table-preferences-editor__row", text: "備考")
    row.find("input[data-field='visible']", visible: :all).uncheck
    page.execute_script("window.__rtpFetchControl.failNextSave()")

    find("[data-action~='rails-table-preferences#saveFromEditor']", match: :first).click

    expect(page.has_css?("[data-rails-table-preferences-target='status']", text: "設定を保存中です...", visible: true)).to eq(true)
    expect(bundled_async_controls_disabled?).to eq(true)

    page.execute_script("window.__rtpFetchControl.releaseFailure()")

    expect(page.has_css?("[data-rails-table-preferences-target='status']", text: "設定の操作を完了できませんでした。", visible: true)).to eq(true)
    expect(bundled_async_controls_disabled?).to eq(false)
  end
end
