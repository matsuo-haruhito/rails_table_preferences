# frozen_string_literal: true

require "spec_helper"

class RailsTablePreferencesSharedPresetSystemSmokeOrdersController < ApplicationController
  helper RailsTablePreferences::TablePreferencesHelper
  include RailsTablePreferences::Controller
  include RailsTablePreferences::TablePreferencesHelper

  DEMO_TABLE_KEY = :rails_table_preferences_shared_preset_system_smoke_orders

  CONTROLLER_SOURCE = begin
    File.read(File.expand_path("../../app/javascript/controllers/rails_table_preferences_controller.js", __dir__))
      .sub("import { Controller } from \"@hotwired/stimulus\"\n\n", "")
      .sub("export default class extends Controller {", "class RailsTablePreferencesController extends Controller {")
  end

  BROWSER_SMOKE_SCRIPT = <<~JS
    (() => {
      const controllerSource = #{CONTROLLER_SOURCE.dump};
      const STORAGE_KEY = "rails-table-preferences-shared-preset-system-smoke";

      class Controller {}

      function capitalize(value) {
        return value.charAt(0).toUpperCase() + value.slice(1)
      }

      function camelToKebab(value) {
        return value.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase()
      }

      function deepCopy(value) {
        if (Array.isArray(value)) return value.map((item) => deepCopy(item))
        if (value && typeof value === "object") return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, deepCopy(item)]))
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

      function ownerPreference(initialSettings) {
        return {
          name: "default",
          default: false,
          editable: true,
          scope_type: "owner",
          settings: deepCopy(initialSettings)
        }
      }

      function sharedPreference(initialSettings) {
        return {
          name: "共有ビュー",
          default: false,
          editable: false,
          scope_type: "shared",
          scope_label: "shared",
          settings: {
            ...deepCopy(initialSettings),
            columns: (initialSettings.columns || []).map((column) => column.key === "memo" ? { ...column, visible: false } : deepCopy(column))
          }
        }
      }

      function readStoredPreference(initialSettings) {
        try {
          const raw = window.sessionStorage.getItem(STORAGE_KEY)
          if (raw) {
            const parsed = JSON.parse(raw)
            if (parsed && typeof parsed === "object") return parsed
          }
        } catch (_error) {
        }
        return ownerPreference(initialSettings)
      }

      function writeStoredPreference(preference) {
        window.sessionStorage.setItem(STORAGE_KEY, JSON.stringify(preference))
        return preference
      }

      function preferencePayload(preference) {
        return {
          name: preference.name,
          default: preference.default === true,
          editable: preference.editable !== false,
          scope_type: preference.scope_type || "owner",
          scope_label: preference.scope_label || "個人",
          settings: deepCopy(preference.settings || {})
        }
      }

      function collectionPayload(storedPreference) {
        return {
          preferences: [
            {
              name: storedPreference.name,
              default: storedPreference.default === true,
              editable: storedPreference.editable !== false,
              scope_type: storedPreference.scope_type || "owner",
              scope_label: storedPreference.scope_label || "個人"
            },
            {
              name: "共有ビュー",
              default: false,
              editable: false,
              scope_type: "shared",
              scope_label: "shared"
            }
          ]
        }
      }

      function installFetchStub(initialSettings) {
        window.fetch = async function(url, options = {}) {
          const method = String(options.method || "GET").toUpperCase()
          const path = new URL(url, window.location.origin).pathname
          const storedPreference = readStoredPreference(initialSettings)

          if (method === "GET") {
            if (/\/preferences\/[^/]+\/[^/]+$/.test(path)) {
              const presetName = decodeURIComponent(path.split("/").pop() || "default")
              const payload = presetName === "共有ビュー" ? sharedPreference(initialSettings) : storedPreference
              return { ok: true, status: 200, json: async () => preferencePayload(payload) }
            }
            return { ok: true, status: 200, json: async () => collectionPayload(storedPreference) }
          }

          const requestPayload = JSON.parse(options.body || "{}")
          const persistedPreference = writeStoredPreference({
            name: requestPayload.name || "default",
            default: requestPayload.default === true,
            editable: true,
            scope_type: "owner",
            settings: deepCopy(requestPayload.settings || {})
          })
          return { ok: true, status: 200, json: async () => preferencePayload(persistedPreference) }
        }
      }

      function mountController() {
        const root = document.querySelector('[data-controller~="rails-table-preferences"]')
        if (!root) return

        const initialSettings = JSON.parse(root.getAttribute("data-rails-table-preferences-settings-value") || "{}")
        const storedPreference = readStoredPreference(initialSettings)
        installFetchStub(initialSettings)

        const factory = new Function("Controller", controllerSource + "; return RailsTablePreferencesController;")
        const RailsTablePreferencesController = factory(Controller)
        const controller = new RailsTablePreferencesController()
        controller.element = root
        controller.identifier = "rails-table-preferences"
        controller.dispatch = function() {}

        installTargetAccessors(controller, RailsTablePreferencesController)
        installValueAccessors(controller, RailsTablePreferencesController)
        controller.__stimulusValues.settings = deepCopy(storedPreference.settings || initialSettings)
        controller.__stimulusValues.name = storedPreference.name
        controller.__stimulusValues.url = `${controller.collectionUrlValue}/${encodeURIComponent(storedPreference.name)}`
        bindActions(controller)
        controller.connect()
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
    <h1>Shared preset smoke</h1>

    <%= table_preferences_editor(
      table_key: DEMO_TABLE_KEY,
      settings: @table_preference_settings,
      columns: @table_columns,
      title: "共有 preset smoke"
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
      { order_no: "A001", memo: "shared preset fallback check" }
    ]
  end
end

Rails.application.routes.disable_clear_and_finalize = true
Rails.application.routes.append do
  get "/rails_table_preferences_system_smoke/shared_preset", to: "rails_table_preferences_shared_preset_system_smoke_orders#index"
end
Rails.application.reload_routes!

RSpec.describe "rails_table_preferences shared preset browser smoke", type: :system, js: true do
  def visit_demo_smoke
    visit "/rails_table_preferences_system_smoke/shared_preset"
    expect(page.has_selector?("body[data-rtp-smoke-ready='true']")).to eq(true)
  end

  def table_column_hidden?(key)
    page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('table [data-rails-table-preferences-column-key="#{key}"]')).every((cell) => cell.hidden)
    JS
  end

  it "loads a shared preset in read-only mode and saves changes into an owner preset" do
    visit_demo_smoke

    preset_select = find("select[data-rails-table-preferences-target='presetSelect']")
    preset_select.select("共有ビュー [shared]")

    expect(page.has_text?("設定を読み込みました。")).to eq(true)
    expect(table_column_hidden?("memo")).to eq(true)
    expect(page.has_css?(".rails-table-preferences-read-only-hint", text: "保存すると個人用の新しい設定として保存されます。", visible: true)).to eq(true)

    delete_button = find("[data-action~='rails-table-preferences#deletePreset']", match: :first)
    expect(delete_button.disabled?).to eq(true)

    row = find(".rails-table-preferences-editor__row", text: "備考")
    row.find("input[data-field='visible']", visible: :all).check
    find("[data-action~='rails-table-preferences#saveFromEditor']", match: :first).click

    expect(page.has_text?("新しい設定を保存しました。")).to eq(true)
    expect(table_column_hidden?("memo")).to eq(false)
    expect(page.has_no_css?(".rails-table-preferences-read-only-hint", visible: true)).to eq(true)
    expect(delete_button.disabled?).to eq(false)

    visit_demo_smoke

    expect(table_column_hidden?("memo")).to eq(false)
    expect(find("select[data-rails-table-preferences-target='presetSelect']")).to have_select(selected: "共有ビュー")
  end
end
