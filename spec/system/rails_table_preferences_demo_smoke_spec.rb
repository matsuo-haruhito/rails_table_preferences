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
      const STORAGE_KEY = "rails-table-preferences-system-smoke-preset";

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

      function smokeRoot() {
        return document.getElementById("rtp-smoke-root") ||
          document.querySelector("[data-rtp-smoke-root]") ||
          document.querySelector('[data-controller~="rails-table-preferences"]') ||
          Array.from(document.querySelectorAll('[data-controller~="rails-table-preferences"]')).find((element) => element.querySelector("table")) ||
          null
      }

      function markSmokeStage(stage) {
        document.body.dataset.rtpSmokeStage = stage
      }

      function mountController() {
        if (window.__rtpController) {
          document.body.dataset.rtpSmokeReady = "true"
          markSmokeStage("ready-existing")
          return
        }

        document.body.dataset.rtpSmokeReady = "false"
        document.body.dataset.rtpSmokeError = ""
        markSmokeStage("mount-start")

        const root = smokeRoot()
        if (!root) {
          document.body.dataset.rtpSmokeError = "root-not-found"
          markSmokeStage("root-not-found")
          return
        }

        try {
          const initialSettings = JSON.parse(root.getAttribute("data-rails-table-preferences-settings-value") || "{}")
          const storedPreference = readStoredPreference(initialSettings)
          installFetchStub(initialSettings)
          markSmokeStage("build-controller")

          const factory = new Function("Controller", controllerSource + "; return RailsTablePreferencesController;")
          const RailsTablePreferencesController = factory(Controller)
          const controller = new RailsTablePreferencesController()
          controller.element = root
          controller.identifier = "rails-table-preferences"
          controller.dispatch = function() {}

          markSmokeStage("bind-accessors")
          installTargetAccessors(controller, RailsTablePreferencesController)
          installValueAccessors(controller, RailsTablePreferencesController)
          controller.__stimulusValues.settings = deepCopy(storedPreference.settings || initialSettings)
          controller.__stimulusValues.name = storedPreference.name || controller.__stimulusValues.name
          controller.__stimulusValues.url = `${controller.collectionUrlValue}/${encodeURIComponent(controller.__stimulusValues.name || "default")}`
          bindActions(controller)

          const originalApplyFromEditor = controller.applyFromEditor.bind(controller)
          controller.applyFromEditor = function(event) {
            const result = originalApplyFromEditor(event)
            document.body.dataset.rtpLastAction = "apply"
            return result
          }

          markSmokeStage("connect")
          controller.connect()
          window.__rtpController = controller
          document.body.dataset.rtpSmokeReady = "true"
          markSmokeStage("ready")
        } catch (error) {
          markSmokeStage("error")
          document.body.dataset.rtpSmokeError = `${error?.name || "Error"}: ${error?.message || String(error)}`
        }
      }

      window.__rtpMountController = mountController
      mountController()
    })();
  JS

  TEMPLATE = <<~ERB
    <% smoke_root_options = { data: @smoke_data_attributes, class: "rails-table-preferences-editor" } %>

    <h1>Rails Table Preferences Demo Smoke</h1>

    <p>
      This screen mirrors the lightweight demo surface closely enough to keep one browser smoke flow under automated coverage.
    </p>

    <div id="rtp-smoke-root"
         data-rtp-smoke-root="true"
         <%= tag.attributes(smoke_root_options) %>>
      <div class="rails-table-preferences-editor__title">デモ受注一覧の表示設定</div>

      <div class="rails-table-preferences-editor__preset">
        <label for="rtp-smoke-preset-select">保存済み設定</label>
        <select id="rtp-smoke-preset-select"
                data-rails-table-preferences-target="presetSelect"
                data-action="rails-table-preferences#selectPreset">
          <option value="default">default</option>
        </select>

        <label for="rtp-smoke-preset-name">設定名</label>
        <input type="text"
               id="rtp-smoke-preset-name"
               value="default"
               data-rails-table-preferences-target="presetName">

        <label class="rails-table-preferences-editor__default-preset">
          <input type="checkbox"
                 data-rails-table-preferences-target="defaultPreset">
          標準設定にする
        </label>
      </div>

      <p class="rails-table-preferences-editor__hint"
         data-rails-table-preferences-target="readOnlyHint"
         hidden></p>

      <div data-rails-table-preferences-target="editorRows" class="rails-table-preferences-editor__rows"></div>
      <div class="rails-table-preferences-editor__status"
           data-rails-table-preferences-target="status"
           role="status"
           aria-live="polite"
           aria-atomic="true"
           aria-label="保存状態"></div>

      <div class="rails-table-preferences-editor__actions">
        <button type="button" data-action="rails-table-preferences#applyFromEditor">適用</button>
        <button type="button" data-action="rails-table-preferences#saveFromEditor">保存</button>
        <button type="button" data-action="rails-table-preferences#createPresetFromEditor">別名で保存</button>
        <button type="button"
                data-action="rails-table-preferences#deletePreset"
                title="この保存済み設定を削除します。よろしいですか？"
                aria-label="削除: この保存済み設定を削除します。よろしいですか？">削除</button>
        <button type="button" data-action="rails-table-preferences#resetEditor">リセット</button>
      </div>

      <table class="table">
        <thead>
          <tr>
            <th data-rails-table-preferences-column-key="order_no">受注番号</th>
            <th data-rails-table-preferences-column-key="customer_name">得意先名</th>
            <th data-rails-table-preferences-column-key="delivery_date">納品日</th>
            <th data-rails-table-preferences-column-key="status">状態</th>
            <th data-rails-table-preferences-column-key="confirmed">確認済</th>
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
              <td data-rails-table-preferences-column-key="confirmed"><%= order[:confirmed] ? "はい" : "いいえ" %></td>
              <td data-rails-table-preferences-column-key="amount"><%= number_with_delimiter(order[:amount]) %></td>
              <td data-rails-table-preferences-column-key="shipping_code"><%= order[:shipping_code] %></td>
              <td data-rails-table-preferences-column-key="shipping_notes"><%= order[:shipping_notes] %></td>
              <td data-rails-table-preferences-column-key="memo"><%= order[:memo] %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>

    <script><%= raw self.class::BROWSER_SMOKE_SCRIPT %></script>
  ERB

  def index
    @table_columns = table_columns
    @table_preference_settings = rails_table_preference_settings(table_key: DEMO_TABLE_KEY)
    @smoke_data_attributes = table_preferences_data_attributes(
      table_key: DEMO_TABLE_KEY,
      settings: @table_preference_settings,
      columns: @table_columns
    )
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
      table_preferences_column(
        :confirmed,
        label: "確認済",
        default_width: 100,
        filter: { type: :boolean, param: :confirmed }
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
        confirmed: true,
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
        confirmed: false,
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
        confirmed: true,
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
  def visit_demo_smoke
    visit "/rails_table_preferences_system_smoke/orders"

    expect(page).to have_css("#rtp-smoke-root[data-rtp-smoke-root='true']", visible: false)

    page.execute_script(<<~JS, RailsTablePreferencesSystemSmokeOrdersController::BROWSER_SMOKE_SCRIPT)
      document.body.dataset.rtpHarnessWrapper = "started"
      new Function(arguments[0])()
      document.body.dataset.rtpHarnessWrapper = "completed"
    JS

    expect(page).to have_css("body[data-rtp-harness-wrapper='completed']", visible: false)
  end

  def ensure_smoke_controller_mounted
    smoke_ready = page.evaluate_script("document.body.dataset.rtpSmokeReady || ''")
    smoke_error = page.evaluate_script("document.body.dataset.rtpSmokeError || ''")
    smoke_stage = page.evaluate_script("document.body.dataset.rtpSmokeStage || ''")
    mount_present = page.evaluate_script("typeof window.__rtpMountController")
    controller_present = page.evaluate_script("typeof window.__rtpController")
    wrapper_state = page.evaluate_script("document.body.dataset.rtpHarnessWrapper || ''")

    expect(smoke_ready).to eq("true"), "smoke mount failed at stage=#{smoke_stage.inspect} error=#{smoke_error.inspect} mount=#{mount_present.inspect} controller=#{controller_present.inspect} wrapper=#{wrapper_state.inspect}"
    expect(smoke_error).to eq("")
    expect(smoke_stage).to match(/ready/)
  end

  def filter_button_selector(key)
    %[button[data-rails-table-preferences-filter-button][data-rails-table-preferences-column-key='#{key}']]
  end

  def filter_panel_selector(key)
    %[.rails-table-preferences-filter-panel[data-rails-table-preferences-column-key='#{key}']]
  end

  def editor_row_selector(key)
    %[.rails-table-preferences-editor__row[data-rails-table-preferences-column-key='#{key}']]
  end

  def filter_button_attribute(key, attribute)
    page.evaluate_script(<<~JS)
      (() => {
        const button = document.querySelector(#{filter_button_selector(key).inspect})
        return button ? button.getAttribute(#{attribute.inspect}) : null
      })()
    JS
  end

  def filter_button_has_attribute?(key, attribute)
    page.evaluate_script(<<~JS)
      (() => {
        const button = document.querySelector(#{filter_button_selector(key).inspect})
        return button ? button.hasAttribute(#{attribute.inspect}) : false
      })()
    JS
  end

  def open_filter_panel_for(key)
    find(filter_button_selector(key), visible: :all).click
    expect(page.has_css?(filter_panel_selector(key))).to eq(true)
  end

  it "renders the demo surface and hides a column through apply" do
    visit_demo_smoke
    ensure_smoke_controller_mounted

    expect(page.has_text?("Rails Table Preferences Demo Smoke")).to eq(true)
    expect(page.has_css?("th[data-rails-table-preferences-column-key='order_no']", text: "受注番号")).to eq(true)
    expect(page.has_no_css?("th[data-rails-table-preferences-column-key='internal_cost']")).to eq(true)
    expect(page.has_css?(editor_row_selector("customer_name"), visible: :all)).to eq(true)

    row = find(editor_row_selector("customer_name"), visible: :all)
    expect(row.find("input[data-field='visible']", visible: :all).checked?).to eq(true)

    row.find("input[data-field='visible']", visible: :all).uncheck
    find("[data-action~='rails-table-preferences#applyFromEditor']", match: :first).click

    expect(page.has_text?("表示設定を更新しました。")).to eq(true)
    expect(page.has_no_css?("th[data-rails-table-preferences-column-key='customer_name']")).to eq(true)
    expect(page.evaluate_script("Array.from(document.querySelectorAll('th[data-rails-table-preferences-column-key=\"order_no\"]')).every((cell) => !cell.hidden)")).to eq(true)
  end

  it "saves a visibility change and restores it after reload" do
    visit_demo_smoke
    ensure_smoke_controller_mounted

    row = find(editor_row_selector("customer_name"), visible: :all)
    row.find("input[data-field='visible']", visible: :all).uncheck
    find("[data-action~='rails-table-preferences#saveFromEditor']", match: :first).click

    expect(page.has_text?("設定を保存しました。")).to eq(true)
    expect(page.evaluate_script("Array.from(document.querySelectorAll('table [data-rails-table-preferences-column-key=\"customer_name\"]')).every((cell) => cell.hidden)")).to eq(true)

    visit_demo_smoke
    ensure_smoke_controller_mounted

    expect(page.evaluate_script("Array.from(document.querySelectorAll('table [data-rails-table-preferences-column-key=\"customer_name\"]')).every((cell) => cell.hidden)")).to eq(true)
    row = find(editor_row_selector("customer_name"), visible: :all)
    expect(row.find("input[data-field='visible']", visible: :all).checked?).to eq(false)
  end

  it "opens the bundled filter panel from the header button" do
    visit_demo_smoke
    ensure_smoke_controller_mounted

    button = find(filter_button_selector("customer_name"), visible: :all)
    expect(button["aria-expanded"]).to eq("false")

    button.click

    expect(button["aria-expanded"]).to eq("true")
    expect(page.has_css?(".rails-table-preferences-filter-panel[data-rails-table-preferences-column-key='customer_name'] [data-field='operator']")).to eq(true)
  end

  it "summarizes the active filter button through title and aria-label" do
    visit_demo_smoke
    ensure_smoke_controller_mounted

    expect(filter_button_attribute("customer_name", "title")).to eq("絞り込み: 得意先名")
    expect(filter_button_has_attribute?("customer_name", "aria-label")).to eq(false)

    open_filter_panel_for("customer_name")
    find(".rails-table-preferences-filter-panel[data-rails-table-preferences-column-key='customer_name'] [data-field='values']", visible: :all).fill_in(with: "東京")
    click_button "適用"

    expect(filter_button_attribute("customer_name", "title")).to eq("絞り込み: 得意先名 (含む: 東京)")
