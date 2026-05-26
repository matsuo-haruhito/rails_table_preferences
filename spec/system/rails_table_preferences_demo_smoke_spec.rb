# frozen_string_literal: true

require "spec_helper"

class RailsTablePreferencesSystemSmokeOrdersController < ApplicationController
  helper RailsTablePreferences::TablePreferencesHelper
  include RailsTablePreferences::Controller
  include RailsTablePreferences::TablePreferencesHelper

  DEMO_TABLE_KEY = :rails_table_preferences_system_smoke_orders

  CONTROLLER_SOURCE = begin
    File.read(File.expand_path("../../app/javascript/controllers/rails_table_preferences_controller.js", __dir__))
      .sub("import { Controller } from \"@hotwired/stimulus\"\n\n", "")
      .sub("export default class extends Controller {", "class RailsTablePreferencesController extends Controller {")
  end

  BROWSER_SMOKE_SCRIPT = <<~JS
    (() => {
      const controllerSource = #{CONTROLLER_SOURCE.dump};

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
          Object.defineProperty(controller, `has${capitalize(name)}Value`, {
            get() { return controller.__stimulusValues[name] !== undefined && controller.__stimulusValues[name] !== null }
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

      function installFetchStub() {
        window.fetch = async function(_url, options = {}) {
          const method = String(options.method || "GET").toUpperCase()
          if (method === "GET") {
            return {
              ok: true,
              status: 200,
              json: async () => ({ preferences: [{ name: "default", default: false, editable: true }] })
            }
          }

          return {
            ok: true,
            status: 200,
            json: async () => ({ name: "default", default: false, editable: true, settings: deepCopy(window.__rtpController.settingsValue) })
          }
        }
      }

      function mountController() {
        const root = document.querySelector('[data-controller~="rails-table-preferences"]')
        if (!root) return

        installFetchStub()

        const factory = new Function(`${controllerSource}; return RailsTablePreferencesController;`)
        const RailsTablePreferencesController = factory()
        const controller = new RailsTablePreferencesController()
        controller.element = root
        controller.identifier = "rails-table-preferences"
        controller.dispatch = function() {}

        installTargetAccessors(controller, RailsTablePreferencesController)
        installValueAccessors(controller, RailsTablePreferencesController)
        bindActions(controller)

        const originalApplyFromEditor = controller.applyFromEditor.bind(controller)
        controller.applyFromEditor = function(event) {
          const result = originalApplyFromEditor(event)
          document.body.dataset.rtpLastAction = "apply"
          return result
        }

        controller.connect()
        window.__rtpController = controller
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
    <h1>Rails Table Preferences Demo Smoke</h1>

    <p>
      This screen mirrors the lightweight demo surface closely enough to keep one browser smoke flow under automated coverage.
    </p>

    <%= table_preferences_editor(
      table_key: DEMO_TABLE_KEY,
      settings: @table_preference_settings,
      columns: @table_columns,
      title: "デモ受注一覧の表示設定"
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
          <th data-rails-table-preferences-column-key="customer_name">得意先名</th>
          <th data-rails-table-preferences-column-key="delivery_date">納品日</th>
          <th data-rails-table-preferences-column-key="status">状態</th>
          <th data-rails-table-preferences-column-key="amount">金額</th>
          <th data-rails-table-preferences-column-key="shipping_code">配送コード</th>
          <th data-rails-table-preferences-column-key="shipping_notes">配送メモ</th>
          <th data-rails-table-preferences-column-key="memo">備考</th>
        </tr>
      </thead>
      <tbody>
        <% @orders.each do |order| %>
          <tr>
            <td data-rails-table-preferences-column-key="order_no"><%= order[:order_no] %></td>
            <td data-rails-table-preferences-column-key="customer_name"><%= order[:customer_name] %></td>
            <td data-rails-table-preferences-column-key="delivery_date"><%= l(order[:delivery_date]) %></td>
            <td data-rails-table-preferences-column-key="status"><%= order[:status] %></td>
            <td data-rails-table-preferences-column-key="amount"><%= number_with_delimiter(order[:amount]) %></td>
            <td data-rails-table-preferences-column-key="shipping_code"><%= order[:shipping_code] %></td>
            <td data-rails-table-preferences-column-key="shipping_notes"><%= order[:shipping_notes] %></td>
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
      table_preferences_column(:order_no, label: "受注番号", default_width: 120, sortable: true),
      table_preferences_column(
        :customer_name,
        label: "得意先名",
        default_width: 240,
        default_truncate: 24,
        filter: { type: :text, param: :search_word },
        sortable: true
      ),
      table_preferences_column(
        :delivery_date,
        label: "納品日",
        default_width: 140,
        filter: { type: :date, from_param: :from_delivery_date, to_param: :to_delivery_date },
        sortable: true
      ),
      table_preferences_column(
        :status,
        label: "状態",
        default_width: 120,
        filter: { type: :select, param: :status, options: ["未出荷", "出荷済", "保留"] },
        sortable: true
      ),
      table_preferences_column(:amount, label: "金額", default_width: 120, sortable: true),
      table_preferences_column(:shipping_code, label: "配送コード", default_width: 140, overflow: "nowrap"),
      table_preferences_column(:shipping_notes, label: "配送メモ", default_width: 160, overflow: "wrap"),
      table_preferences_column(:memo, label: "備考", default_width: 180, default_truncate: 24),
      table_preferences_column(:internal_cost, label: "内部原価", ignored: true)
    ]
  end

  def demo_orders
    [
      {
        order_no: "A001",
        customer_name: "山田商事 東京本店",
        delivery_date: Date.current,
        status: "未出荷",
        amount: 12_000,
        shipping_code: "TOKYO-AM-PRIMARY-001",
        shipping_notes: "午前指定のため、到着後すぐに検品できるよう納品書を最上段へ入れてください。",
        memo: "初回出荷のため伝票控えを同梱してください。"
      },
      {
        order_no: "A002",
        customer_name: "田中物流 関西センター",
        delivery_date: Date.current + 1.day,
        status: "出荷済",
        amount: 34_000,
        shipping_code: "KANSAI-PALLET-RETURN-220",
        shipping_notes: "午後着。パレット回収あり。荷下ろし口の案内を事前連絡すると現場が止まりにくい案件です。",
        memo: "列幅変更と省略表示の確認に使えます。"
      },
      {
        order_no: "A003",
        customer_name: "佐藤食品 冷凍倉庫",
        delivery_date: Date.current + 2.days,
        status: "保留",
        amount: 56_000,
        shipping_code: "FREEZER-CHECK-WAITING-305",
        shipping_notes: "温度帯確認待ち。確認が取れしだい、冷凍便と常温便のどちらで出すかを切り替える予定です。",
        memo: "ステータス絞り込みと並び替えの確認向けです。"
      }
    ]
  end
end

Rails.application.routes.disable_clear_and_finalize = true
Rails.application.routes.append do
  get "/rails_table_preferences_system_smoke/orders", to: "rails_table_preferences_system_smoke_orders#index"
end
Rails.application.reload_routes!

RSpec.describe "rails_table_preferences demo browser smoke", type: :system, js: true do
  it "renders the demo surface and hides a column through apply" do
    visit "/rails_table_preferences_system_smoke/orders"

    expect(page.has_selector?("body[data-rtp-smoke-ready='true']")).to eq(true)
    expect(page.has_text?("Rails Table Preferences Demo Smoke")).to eq(true)
    expect(page.has_css?("th[data-rails-table-preferences-column-key='order_no']", text: "受注番号")).to eq(true)
    expect(page.has_no_css?("th[data-rails-table-preferences-column-key='internal_cost']")).to eq(true)
    expect(page.has_css?(".rails-table-preferences-editor__row", text: "得意先名")).to eq(true)

    row = find(".rails-table-preferences-editor__row", text: "得意先名")
    row.find("input[data-field='visible']", visible: :all).uncheck
    find("[data-action~='rails-table-preferences#applyFromEditor']", match: :first).click

    expect(page.has_selector?("body[data-rtp-last-action='apply']")).to eq(true)
    expect(page.evaluate_script("Array.from(document.querySelectorAll('th[data-rails-table-preferences-column-key=\"customer_name\"]')).every((cell) => cell.hidden)")).to eq(true)
    expect(page.evaluate_script("Array.from(document.querySelectorAll('td[data-rails-table-preferences-column-key=\"customer_name\"]')).every((cell) => cell.hidden)")).to eq(true)
    expect(page.evaluate_script("Array.from(document.querySelectorAll('th[data-rails-table-preferences-column-key=\"order_no\"]')).every((cell) => !cell.hidden)")).to eq(true)
  end

  it "auto-fits the representative demo column and keeps overflow modes distinct" do
    visit "/rails_table_preferences_system_smoke/orders"

    expect(page.has_selector?("body[data-rtp-smoke-ready='true']")).to eq(true)

    initial_width = page.evaluate_script(<<~JS)
      (() => {
        const cell = document.querySelector('th[data-rails-table-preferences-column-key="shipping_notes"]')
        return Math.round(cell.getBoundingClientRect().width)
      })()
    JS

    page.execute_script(<<~JS)
      (() => {
        const handle = document.querySelector('th[data-rails-table-preferences-column-key="shipping_notes"] [data-rails-table-preferences-resize-handle]')
        handle.dispatchEvent(new MouseEvent('dblclick', { bubbles: true }))
      })()
    JS

    auto_fit_width = page.evaluate_script(<<~JS)
      (() => {
        const cell = document.querySelector('th[data-rails-table-preferences-column-key="shipping_notes"]')
        return Math.round(cell.getBoundingClientRect().width)
      })()
    JS

    expect(auto_fit_width).to be > initial_width
    expect(page.evaluate_script("document.querySelector('td[data-rails-table-preferences-column-key=\"shipping_notes\"]').dataset.railsTablePreferencesOverflow")).to eq("wrap")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('td[data-rails-table-preferences-column-key=\"shipping_notes\"]')).whiteSpace")).to eq("normal")
    expect(page.evaluate_script("document.querySelector('td[data-rails-table-preferences-column-key=\"shipping_code\"]').dataset.railsTablePreferencesOverflow")).to eq("nowrap")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('td[data-rails-table-preferences-column-key=\"shipping_code\"]')).whiteSpace")).to eq("nowrap")
    expect(page.evaluate_script("document.querySelector('td[data-rails-table-preferences-column-key=\"memo\"]').dataset.railsTablePreferencesOverflow")).to eq("ellipsis")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('td[data-rails-table-preferences-column-key=\"memo\"]')).textOverflow")).to eq("ellipsis")
  end
end
