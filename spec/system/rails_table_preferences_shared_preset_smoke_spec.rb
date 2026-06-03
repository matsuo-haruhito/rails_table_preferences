# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Rails Table Preferences shared preset fallback smoke", type: :system, js: true do
  before do
    driven_by(:selenium_chrome_headless)
  end

  it "loads a shared preset as read-only and saves edits through owner fallback" do
    visit "about:blank"
    install_shared_preset_smoke_harness

    select "共有ビュー [shared]", from: "preset-select"

    expect(page).to have_css('[data-rails-table-preferences-target="readOnlyHint"]', visible: true)
    expect(page).to have_field("preset-default", disabled: true)
    expect(page).to have_button("削除", disabled: true)
    expect(find_button("保存")["data-rails-table-preferences-non-editable-fallback"]).to eq("true")

    within('[data-rails-table-preferences-column-key="customer_name"]') do
      expect(page).to have_css('input[type="checkbox"][disabled]')
    end

    click_button "保存"

    expect(page).to have_css('[data-rails-table-preferences-target="status"]', text: "新しい設定を保存しました。")

    mutations = page.evaluate_script("window.__rtpSharedPresetSmoke.mutations")
    expect(mutations.map { |mutation| mutation.fetch("method") }).to eq(["POST"])
    expect(mutations.first.fetch("name")).to eq("共有ビュー")
    expect(mutations.first.fetch("settings").fetch("columns")).to include(
      hash_including("key" => "amount", "visible" => false)
    )
  end

  def install_shared_preset_smoke_harness
    controller_source = File.read(
      Rails.root.join("app/javascript/controllers/rails_table_preferences_controller.js")
    )

    page.execute_script(<<~JS, controller_source)
      const source = arguments[0];

      document.body.innerHTML = `
        <section id="smoke-root">
          <label for="preset-select">Preset</label>
          <select id="preset-select" data-rails-table-preferences-target="presetSelect" data-action="rails-table-preferences#selectPreset"></select>

          <label for="preset-name">Name</label>
          <input id="preset-name" data-rails-table-preferences-target="presetName" />

          <label for="preset-default">
            <input id="preset-default" type="checkbox" data-rails-table-preferences-target="defaultPreset" />
            Default
          </label>

          <p data-rails-table-preferences-target="readOnlyHint" hidden>Shared preset is read-only.</p>
          <div data-rails-table-preferences-target="editorRows"></div>
          <p data-rails-table-preferences-target="status"></p>

          <button type="button" data-rails-table-preferences-target="savePresetButton" data-action="rails-table-preferences#saveFromEditor">保存</button>
          <button type="button" data-rails-table-preferences-target="deletePresetButton" data-action="rails-table-preferences#deletePreset">削除</button>

          <table>
            <thead>
              <tr>
                <th data-column-key="order_no">Order No</th>
                <th data-column-key="customer_name">Customer</th>
                <th data-column-key="amount">Amount</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td data-column-key="order_no">A-100</td>
                <td data-column-key="customer_name">Kobayashi</td>
                <td data-column-key="amount">12,000</td>
              </tr>
            </tbody>
          </table>
        </section>
      `;

      const root = document.getElementById("smoke-root");
      const initialColumns = [
        { key: "order_no", label: "Order No", visible: true, order: 1 },
        { key: "customer_name", label: "Customer", visible: true, order: 2 },
        { key: "amount", label: "Amount", visible: true, order: 3 }
      ];
      const initialSettings = {
        columns: initialColumns,
        sort: [],
        filters: {},
        density: "comfortable"
      };

      root.dataset.railsTablePreferencesTableKeyValue = "shared_preset_smoke_orders";
      root.dataset.railsTablePreferencesColumnsValue = JSON.stringify(initialColumns);
      root.dataset.railsTablePreferencesSettingsValue = JSON.stringify(initialSettings);
      root.dataset.railsTablePreferencesPreferencesUrlValue = "/rails_table_preferences_shared_preset_smoke/preferences";
      root.dataset.railsTablePreferencesPreferenceUrlValue = "/rails_table_preferences_shared_preset_smoke/preferences/:name";

      window.__rtpSharedPresetSmoke = { mutations: [] };

      class Controller {
        constructor(element) {
          this.element = element;
        }
      }

      function capitalize(value) {
        return value.charAt(0).toUpperCase() + value.slice(1);
      }

      function camelToKebab(value) {
        return value.replace(/[A-Z]/g, (letter) => `-${letter.toLowerCase()}`);
      }

      function deepCopy(value) {
        return value == null ? value : JSON.parse(JSON.stringify(value));
      }

      function descriptorType(valueName, descriptor) {
        if (typeof descriptor === "function") return descriptor;
        if (descriptor && typeof descriptor === "object" && descriptor.type) return descriptor.type;
        return String;
      }

      function descriptorDefault(valueName, descriptor) {
        if (descriptor && typeof descriptor === "object" && Object.prototype.hasOwnProperty.call(descriptor, "default")) {
          return descriptor.default;
        }
        return undefined;
      }

      function parseValue(raw, type, fallback) {
        if (raw == null) return typeof fallback === "undefined" ? undefined : deepCopy(fallback);
        if (type === Boolean) return raw === "true";
        if (type === Number) return Number(raw);
        if (type === Array || type === Object) return JSON.parse(raw);
        return raw;
      }

      function installTargetAccessors(controllerClass) {
        for (const targetName of controllerClass.targets || []) {
          Object.defineProperty(controllerClass.prototype, `${targetName}Target`, {
            configurable: true,
            get() {
              return this.element.querySelector(`[data-rails-table-preferences-target~="${targetName}"]`);
            }
          });

          Object.defineProperty(controllerClass.prototype, `${targetName}Targets`, {
            configurable: true,
            get() {
              return Array.from(this.element.querySelectorAll(`[data-rails-table-preferences-target~="${targetName}"]`));
            }
          });

          Object.defineProperty(controllerClass.prototype, `has${capitalize(targetName)}Target`, {
            configurable: true,
            get() {
              return !!this.element.querySelector(`[data-rails-table-preferences-target~="${targetName}"]`);
            }
          });
        }
      }

      function installValueAccessors(controllerClass) {
        for (const [valueName, descriptor] of Object.entries(controllerClass.values || {})) {
          const type = descriptorType(valueName, descriptor);
          const fallback = descriptorDefault(valueName, descriptor);
          const dataName = `railsTablePreferences${capitalize(valueName)}Value`;
          const kebabName = `data-rails-table-preferences-${camelToKebab(valueName)}-value`;

          Object.defineProperty(controllerClass.prototype, `${valueName}Value`, {
            configurable: true,
            get() {
              const raw = this.element.dataset[dataName] || this.element.getAttribute(kebabName);
              return parseValue(raw, type, fallback);
            },
            set(value) {
              const serialized = type === Array || type === Object ? JSON.stringify(value) : String(value);
              this.element.dataset[dataName] = serialized;
              this.element.setAttribute(kebabName, serialized);
            }
          });

          Object.defineProperty(controllerClass.prototype, `has${capitalize(valueName)}Value`, {
            configurable: true,
            get() {
              return this.element.dataset[dataName] != null || this.element.hasAttribute(kebabName);
            }
          });
        }
      }

      function bindActions(root, controller) {
        root.querySelectorAll("[data-action]").forEach((element) => {
          const actions = element.getAttribute("data-action").split(/\s+/).filter(Boolean);
          actions.forEach((action) => {
            const [eventPart, methodPart] = action.includes("->") ? action.split("->") : [null, action];
            const [, methodName] = methodPart.split("#");
            const eventName = eventPart || (element.tagName === "SELECT" || element.tagName === "INPUT" ? "change" : "click");
            element.addEventListener(eventName, (event) => controller[methodName](event));
          });
        });
      }

      function installFetchStub() {
        const preferencePayloads = {
          default: {
            name: "default",
            default: true,
            editable: true,
            settings: {
              columns: [
                { key: "order_no", label: "Order No", visible: true, order: 1 },
                { key: "customer_name", label: "Customer", visible: true, order: 2 },
                { key: "amount", label: "Amount", visible: true, order: 3 }
              ],
              sort: [],
              filters: {},
              density: "comfortable"
            }
          },
          "共有ビュー": {
            name: "共有ビュー",
            default: false,
            editable: false,
            scope_type: "shared",
            scope_label: "shared",
            settings: {
              columns: [
                { key: "order_no", label: "Order No", visible: true, order: 1 },
                { key: "customer_name", label: "Customer", visible: true, order: 2 },
                { key: "amount", label: "Amount", visible: false, order: 3 }
              ],
              sort: [],
              filters: {},
              density: "comfortable"
            }
          }
        };

        function jsonResponse(payload, status = 200) {
          return Promise.resolve(new Response(JSON.stringify(payload), {
            status,
            headers: { "Content-Type": "application/json" }
          }));
        }

        window.fetch = async (url, options = {}) => {
          const method = (options.method || "GET").toUpperCase();
          const key = decodeURIComponent(String(url).split("/").pop() || "");

          if (method === "GET" && preferencePayloads[key]) {
            return jsonResponse(preferencePayloads[key]);
          }

          if (method === "GET") {
            return jsonResponse({ preferences: Object.values(preferencePayloads) });
          }

          const body = options.body ? JSON.parse(options.body) : {};
          window.__rtpSharedPresetSmoke.mutations.push({
            method,
            url: String(url),
            name: body.name,
            settings: body.settings
          });

          if (method !== "POST") {
            return jsonResponse({ error: "Shared preset should be saved through collection fallback" }, 500);
          }

          return jsonResponse({
            name: body.name,
            default: !!body.default,
            editable: true,
            settings: body.settings
          });
        };
      }

      const transformed = source
        .split("\\n")
        .filter((line) => !line.startsWith("import "))
        .join("\\n")
        .replace("export default class", "class RailsTablePreferencesController");
      const RailsTablePreferencesController = Function("Controller", `${transformed}; return RailsTablePreferencesController;`)(Controller);

      installTargetAccessors(RailsTablePreferencesController);
      installValueAccessors(RailsTablePreferencesController);
      installFetchStub();

      const controller = new RailsTablePreferencesController(root);
      window.__rtpSharedPresetSmoke.controller = controller;
      bindActions(root, controller);
      controller.connect();
    JS

    expect(page).to have_select("preset-select", with_options: ["共有ビュー [shared]"])
  end
end
