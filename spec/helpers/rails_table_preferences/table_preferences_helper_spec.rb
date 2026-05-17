# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  describe "#table_preferences_preference_url" do
    it "builds a URL using the configured mount path" do
      RailsTablePreferences.configuration.mount_path = "/preferences_engine"

      expect(helper.table_preferences_preference_url(table_key: :orders, name: "default")).to eq(
        "/preferences_engine/preferences/orders/default"
      )
    end

    it "URL-encodes table key and name" do
      expect(helper.table_preferences_preference_url(table_key: "order details", name: "my default")).to eq(
        "/rails_table_preferences/preferences/order%20details/my%20default"
      )
    end
  end

  describe "#table_preferences_collection_url" do
    it "builds a collection URL for table presets" do
      expect(helper.table_preferences_collection_url(table_key: :orders)).to eq(
        "/rails_table_preferences/preferences/orders"
      )
    end
  end

  describe "#table_preferences_data_attributes" do
    it "returns Stimulus data attributes for a table" do
      attributes = helper.table_preferences_data_attributes(
        table_key: :orders,
        columns: [helper.table_preferences_column(:customer_code, label: "Customer Code", default_width: 120)]
      )

      expect(attributes).to include(
        controller: "rails-table-preferences",
        rails_table_preferences_table_key_value: "orders",
        rails_table_preferences_name_value: "default",
        rails_table_preferences_url_value: "/rails_table_preferences/preferences/orders/default",
        rails_table_preferences_collection_url_value: "/rails_table_preferences/preferences/orders"
      )
      expect(JSON.parse(attributes[:rails_table_preferences_settings_value])).to eq(
        "columns" => [],
        "filters" => {},
        "sorts" => []
      )
      expect(JSON.parse(attributes[:rails_table_preferences_columns_value])).to eq(
        [
          {
            "key" => "customer_code",
            "label" => "Customer Code",
            "visible" => true,
            "width" => 120,
            "pinned" => false
          }
        ]
      )
    end

    it "includes filter and sortable metadata in columns JSON" do
      attributes = helper.table_preferences_data_attributes(
        table_key: :orders,
        columns: [
          helper.table_preferences_column(
            :customer_name,
            label: "得意先名",
            filter: { type: :text, operators: %i[contains equals blank] },
            sortable: true
          )
        ]
      )

      expect(JSON.parse(attributes[:rails_table_preferences_columns_value])).to eq(
        [
          {
            "key" => "customer_name",
            "label" => "得意先名",
            "visible" => true,
            "pinned" => false,
            "filter" => {
              "type" => "text",
              "operators" => %w[contains equals blank]
            },
            "sortable" => true
          }
        ]
      )
    end

    it "excludes ignored columns from columns and saved settings" do
      attributes = helper.table_preferences_data_attributes(
        table_key: :orders,
        columns: [
          helper.table_preferences_column(:customer_code, label: "Customer Code"),
          helper.table_preferences_column(:internal_cost, label: "Internal Cost", ignored: true),
          helper.table_preferences_column(:secret_note, label: "Secret Note")
        ],
        ignored_columns: [:secret_note],
        settings: {
          columns: [
            { key: "customer_code", visible: true, order: 10 },
            { key: "internal_cost", visible: true, order: 20 },
            { key: "secret_note", visible: true, order: 30 }
          ],
          filters: {
            customer_code: { operator: :contains, value: "001" },
            internal_cost: { operator: :gteq, value: 100 },
            secret_note: { operator: :contains, value: "hidden" }
          },
          sorts: [
            { key: :customer_code, direction: :asc },
            { key: :internal_cost, direction: :desc },
            { key: :secret_note, direction: :asc }
          ]
        }
      )

      settings = JSON.parse(attributes[:rails_table_preferences_settings_value])
      expect(JSON.parse(attributes[:rails_table_preferences_columns_value]).map { |column| column["key"] }).to eq(["customer_code"])
      expect(settings["columns"].map { |column| column["key"] }).to eq(["customer_code"])
      expect(settings["filters"].keys).to eq(["customer_code"])
      expect(settings["sorts"].map { |sort| sort["key"] }).to eq(["customer_code"])
    end
  end

  describe "#table_preferences_column" do
    it "builds a column definition hash" do
      expect(helper.table_preferences_column(:customer_code, label: "Customer Code", default_order: 10)).to eq(
        "key" => "customer_code",
        "label" => "Customer Code",
        "visible" => true,
        "order" => 10,
        "pinned" => false,
        "ignored" => false
      )
    end

    it "builds a filterable and sortable column definition hash" do
      expect(
        helper.table_preferences_column(
          :status,
          label: "状態",
          filter: :select,
          sortable: true
        )
      ).to include(
        "key" => "status",
        "label" => "状態",
        "filter" => { "type" => "select" },
        "sortable" => true
      )
    end

    it "uses locale-backed labels" do
      I18n.backend.store_translations(:en, activerecord: { attributes: { order: { customer_code: "Customer Code from locale" } } })

      expect(helper.table_preferences_column(:customer_code, model_name: :order)["label"]).to eq("Customer Code from locale")
    end
  end

  describe "#table_preferences_columns" do
    it "filters ignored columns" do
      columns = helper.table_preferences_columns(
        [
          :customer_code,
          { key: :internal_cost, ignored: true },
          { key: :secret_note }
        ],
        ignored_columns: ["secret_note"]
      )

      expect(columns.map { |column| column["key"] }).to eq(["customer_code"])
      expect(columns.first).not_to have_key("ignored")
    end

    it "preserves filter and sortable metadata from hash definitions" do
      columns = helper.table_preferences_columns(
        [
          { key: :customer_name, filter: { type: :text }, sortable: true }
        ]
      )

      expect(columns.first).to include(
        "filter" => { "type" => "text" },
        "sortable" => true
      )
    end
  end

  describe "#table_preferences_params" do
    it "returns controller params adapter output" do
      params = helper.table_preferences_params(
        settings: {
          filters: {
            customer_name: { operator: :contains, value: "山田" },
            status: { operator: :in, values: %w[未出荷 出荷済] }
          },
          sorts: [{ key: :delivery_date, direction: :desc }]
        },
        columns: [
          { key: :customer_name, filter: { param: :search_word } },
          { key: :status, filter: { values_param: :statuses } },
          { key: :delivery_date, sort_param: :delivery_on }
        ]
      )

      expect(params).to eq(
        "search_word" => "山田",
        "statuses" => %w[未出荷 出荷済],
        "sort" => "-delivery_on"
      )
    end

    it "returns Ransack adapter output" do
      params = helper.table_preferences_params(
        settings: {
          filters: { customer_name: { operator: :contains, value: "山田" } },
          sorts: [{ key: :delivery_date, direction: :desc }]
        },
        columns: [:customer_name, :delivery_date],
        adapter: :ransack
      )

      expect(params).to eq(
        "customer_name_cont" => "山田",
        "s" => ["delivery_date desc"]
      )
    end

    it "filters ignored columns before converting params" do
      params = helper.table_preferences_params(
        settings: {
          filters: {
            customer_name: { operator: :contains, value: "山田" },
            secret_note: { operator: :contains, value: "hidden" }
          },
          sorts: [
            { key: :secret_note, direction: :desc }
          ]
        },
        columns: [
          { key: :customer_name, filter: { param: :search_word } },
          { key: :secret_note, filter: true, sortable: true }
        ],
        ignored_columns: [:secret_note]
      )

      expect(params).to eq("search_word" => "山田")
    end
  end

  describe "#table_preferences_hidden_fields" do
    it "renders hidden fields for scalar, array, and sort params" do
      html = helper.table_preferences_hidden_fields(
        settings: {
          filters: {
            customer_name: { operator: :contains, value: "山田" },
            status: { operator: :in, values: %w[未出荷 出荷済] }
          },
          sorts: [{ key: :delivery_date, direction: :desc }]
        },
        columns: [
          { key: :customer_name, filter: { param: :search_word } },
          { key: :status, filter: { values_param: :statuses } },
          { key: :delivery_date, sort_param: :delivery_on }
        ]
      )

      expect(html).to include('type="hidden" name="search_word" value="山田"')
      expect(html).to include('type="hidden" name="statuses[]" value="未出荷"')
      expect(html).to include('type="hidden" name="statuses[]" value="出荷済"')
      expect(html).to include('type="hidden" name="sort" value="-delivery_on"')
    end

    it "renders namespaced hidden fields" do
      html = helper.table_preferences_hidden_fields(
        settings: {
          filters: { customer_name: { operator: :contains, value: "山田" } },
          sorts: [{ key: :delivery_date, direction: :desc }]
        },
        columns: [:customer_name, :delivery_date],
        adapter: :ransack,
        namespace: :q
      )

      expect(html).to include('type="hidden" name="q[customer_name_cont]" value="山田"')
      expect(html).to include('type="hidden" name="q[s][]" value="delivery_date desc"')
    end
  end

  describe "#table_preferences_editor" do
    it "renders an editor container with action buttons" do
      html = helper.table_preferences_editor(table_key: :orders, columns: [:customer_code])

      expect(html).to include("rails-table-preferences-editor")
      expect(html).to include("rails-table-preferences#applyFromEditor")
      expect(html).to include("rails-table-preferences#saveFromEditor")
      expect(html).to include("rails-table-preferences#createPresetFromEditor")
      expect(html).to include("rails-table-preferences#deletePreset")
      expect(html).to include("rails-table-preferences#resetEditor")
    end

    it "renders preset selection and default controls" do
      html = helper.table_preferences_editor(table_key: :orders, name: "inspection", columns: [:customer_code])

      expect(html).to include("rails-table-preferences-target=\"presetSelect\"")
      expect(html).to include("rails-table-preferences#selectPreset")
      expect(html).to include("rails-table-preferences-target=\"defaultPreset\"")
    end

    it "renders localized default labels for Japanese users" do
      I18n.with_locale(:ja) do
        html = helper.table_preferences_editor(table_key: :orders, columns: [:customer_code])

        expect(html).to include("保存済み設定")
        expect(html).to include("設定名")
        expect(html).to include("標準設定にする")
        expect(html).to include("適用")
        expect(html).to include("保存")
        expect(html).to include("別名で保存")
        expect(html).to include("削除")
        expect(html).to include("リセット")
      end
    end

    it "passes localized labels to the Stimulus controller" do
      I18n.with_locale(:ja) do
        html = helper.table_preferences_editor(table_key: :orders, columns: [:customer_code])

        expect(html).to include("rails-table-preferences-order-label-value=\"表示順\"")
        expect(html).to include("rails-table-preferences-width-label-value=\"列幅\"")
        expect(html).to include("rails-table-preferences-truncate-label-value=\"省略文字数\"")
        expect(html).to include("rails-table-preferences-drag-label-value=\"ドラッグして並び替え\"")
        expect(html).to include("rails-table-preferences-resize-label-value=\"列幅を変更\"")
      end
    end

    it "renders a preset name input" do
      html = helper.table_preferences_editor(table_key: :orders, name: "inspection", columns: [:customer_code])

      expect(html).to include("value=\"inspection\"")
      expect(html).to include("rails-table-preferences-target=\"presetName\"")
    end

    it "renders a container used for draggable editor rows" do
      html = helper.table_preferences_editor(table_key: :orders, columns: [:customer_code])

      expect(html).to include("rails-table-preferences-editor__rows")
      expect(html).to include("rails-table-preferences-target=\"editorRows\"")
    end

    it "allows a custom partial" do
      expect(helper).to receive(:render).with(
        hash_including(partial: "shared/custom_table_preferences_editor")
      ).and_return("custom editor")

      expect(helper.table_preferences_editor(table_key: :orders, columns: [], partial: "shared/custom_table_preferences_editor")).to eq("custom editor")
    end
  end
end
