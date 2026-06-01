# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  describe "#table_preferences_table_tag" do
    it "renders a table with preference metadata" do
      html = helper.table_preferences_table_tag(
        table_key: :orders,
        columns: [:customer_code, :customer_name]
      ) { "<tbody></tbody>".html_safe }

      expect(html).to include("data-controller=\"rails-table-preferences\"")
      expect(html).to include("data-rails-table-preferences-table-key-value=\"orders\"")
      expect(html).to include("data-rails-table-preferences-columns-value=")
      expect(html).to include("data-rails-table-preferences-settings-value=")
      expect(html).to include("<tbody></tbody>")
    end

    it "merges a custom data-controller with the default controller" do
      html = helper.table_preferences_table_tag(
        table_key: :orders,
        columns: [:customer_code],
        data: { controller: "orders-table" }
      ) { "".html_safe }

      expect(html).to include("data-controller=\"orders-table rails-table-preferences\"")
    end

    it "keeps the default controller when the custom controller already includes it" do
      html = helper.table_preferences_table_tag(
        table_key: :orders,
        columns: [:customer_code],
        data: { controller: "rails-table-preferences orders-table" }
      ) { "".html_safe }

      expect(html).to include("data-controller=\"rails-table-preferences orders-table\"")
    end

    it "merges custom classes" do
      html = helper.table_preferences_table_tag(
        table_key: :orders,
        columns: [:customer_code],
        class: "table table-striped"
      ) { "".html_safe }

      expect(html).to include("class=\"rails-table-preferences-table table table-striped\"")
    end

    it "marks configured columns" do
      html = helper.table_preferences_table_tag(
        table_key: :orders,
        columns: [:customer_code]
      ) do
        tag.thead do
          tag.tr do
            tag.th("顧客コード", data: { rails_table_preferences_column_key: "customer_code" })
          end
        end
      end

      expect(html).to include("data-rails-table-preferences-column-key=\"customer_code\"")
    end

    it "passes preference urls" do
      html = helper.table_preferences_table_tag(
        table_key: :orders,
        columns: [:customer_code],
        preference_url: "/preferences/orders/default",
        collection_url: "/preferences/orders"
      ) { "".html_safe }

      expect(html).to include("data-rails-table-preferences-url-value=\"/preferences/orders/default\"")
      expect(html).to include("data-rails-table-preferences-collection-url-value=\"/preferences/orders\"")
    end

    it "passes an explicit preference name" do
      html = helper.table_preferences_table_tag(
        table_key: :orders,
        name: "current-user",
        columns: [:customer_code]
      ) { "".html_safe }

      expect(html).to include("data-rails-table-preferences-name-value=\"current-user\"")
    end

    it "accepts TableColumn objects and keeps extra metadata" do
      columns = [
        RailsTablePreferences::TableColumn.new(
          key: :customer_code,
          label: "顧客コード",
          visible: true,
          order: 2,
          width: "12rem",
          truncate: 24
        )
      ]

      html = helper.table_preferences_table_tag(table_key: :orders, columns: columns) { "".html_safe }

      expect(html).to include("customer_code")
      expect(html).to include("顧客コード")
      expect(html).to include("12rem")
      expect(html).to include("24")
    end

    it "builds column definitions from hashes" do
      columns = [
        { key: :customer_code, label: "顧客コード", visible: false, order: 1, width: "10rem", truncate: 12 }
      ]

      html = helper.table_preferences_table_tag(table_key: :orders, columns: columns) { "".html_safe }

      expect(html).to include("customer_code")
      expect(html).to include("顧客コード")
      expect(html).to include("false")
      expect(html).to include("10rem")
      expect(html).to include("12")
    end

    it "uses column definition helper output" do
      helper.table_preferences_column(:customer_code, label: "顧客コード")
      helper.table_preferences_column(:customer_name, label: "顧客名")

      html = helper.table_preferences_table_tag(table_key: :orders) { "".html_safe }

      expect(html).to include("customer_code")
      expect(html).to include("customer_name")
      expect(html).to include("顧客コード")
      expect(html).to include("顧客名")
    end

    it "raises when columns are missing" do
      expect do
        helper.table_preferences_table_tag(table_key: :orders) { "".html_safe }
      end.to raise_error(ArgumentError, /columns must be provided/)
    end

    it "raises when table_key is missing" do
      expect do
        helper.table_preferences_table_tag(columns: [:customer_code]) { "".html_safe }
      end.to raise_error(ArgumentError, /table_key is required/)
    end
  end

  describe "#table_preferences_column" do
    it "builds and stores a column definition" do
      helper.table_preferences_column(:customer_code, label: "顧客コード", visible: false, order: 4, width: "10rem", truncate: 20)

      definitions = helper.table_preferences_columns
      expect(definitions.size).to eq(1)
      expect(definitions.first).to be_a(RailsTablePreferences::TableColumn)
      expect(definitions.first.key).to eq("customer_code")
      expect(definitions.first.label).to eq("顧客コード")
      expect(definitions.first.visible).to be(false)
      expect(definitions.first.order).to eq(4)
      expect(definitions.first.width).to eq("10rem")
      expect(definitions.first.truncate).to eq(20)
    end

    it "supports filter and sortable metadata" do
      helper.table_preferences_column(:customer_name, label: "顧客名", filter: { type: :text }, sortable: true)

      definition = helper.table_preferences_columns.first
      expect(definition.filter).to eq({ "type" => "text" })
      expect(definition.sortable).to be(true)
    end

    it "supports pinned and export metadata" do
      helper.table_preferences_column(:customer_name, label: "顧客名", pinned: true, export_key: :customer_name_for_export)

      definition = helper.table_preferences_columns.first
      expect(definition.pinned).to be(true)
      expect(definition.export_key).to eq("customer_name_for_export")
    end

    it "supports filter option metadata" do
      helper.table_preferences_column(:status, label: "状態", filter: { type: :select, options: ["pending", { value: "shipped", label: "出荷済み" }] })

      definition = helper.table_preferences_columns.first
      expect(definition.filter["options"]).to eq(["pending", { "value" => "shipped", "label" => "出荷済み" }])
    end

    it "supports grouped metadata" do
      helper.table_preferences_column(:customer_name, label: "顧客名", group: "Customer")

      definition = helper.table_preferences_columns.first
      expect(definition.group).to eq("Customer")
      expect(definition.to_h["group"]).to eq("Customer")
    end

    it "keeps empty optional metadata out of the JSON payload" do
      helper.table_preferences_column(:customer_name, label: "顧客名", width: "", truncate: nil, filter: {}, group: "", pinned: false, export_key: "")

      payload = helper.table_preferences_columns.first.to_h

      expect(payload).not_to have_key("width")
      expect(payload).not_to have_key("truncate")
      expect(payload).not_to have_key("filter")
      expect(payload).not_to have_key("group")
      expect(payload).not_to have_key("pinned")
      expect(payload).not_to have_key("export_key")
    end
  end

  describe "#rails_table_preference_settings" do
    it "generates default settings for the provided columns" do
      settings = helper.rails_table_preference_settings([
        RailsTablePreferences::TableColumn.new(key: :customer_code, label: "顧客コード", visible: true, order: 2, width: "12rem"),
        RailsTablePreferences::TableColumn.new(key: :customer_name, label: "顧客名", visible: false, order: 1)
      ])

      expect(settings["columns"].map { |column| column["key"] }).to eq(%w[customer_name customer_code])
      expect(settings["columns"].first).to include("visible" => false, "order" => 1)
      expect(settings["columns"].last).to include("visible" => true, "order" => 2, "width" => "12rem")
    end

    it "builds settings from hash columns" do
      settings = helper.rails_table_preference_settings([
        { key: :customer_code, label: "顧客コード", visible: false, order: 3 }
      ])

      expect(settings["columns"].first).to include("key" => "customer_code", "label" => "顧客コード", "visible" => false, "order" => 3)
    end

    it "returns deep copies so callers can mutate safely" do
      column = RailsTablePreferences::TableColumn.new(key: :customer_code, label: "顧客コード", filter: { type: :text })

      settings = helper.rails_table_preference_settings([column])
      settings["columns"].first["filter"]["type"] = "select"

      expect(column.filter["type"]).to eq("text")
    end
  end

  describe "#rails_table_preference_params" do
    let(:params) do
      ActionController::Parameters.new(
        table_preferences: {
          orders: {
            columns: {
              customer_code: { visible: "0", order: "2", width: "12rem" },
              customer_name: { visible: "1", order: "1", width: "" },
              internal_note: { visible: "false" },
              missing_column: { visible: "1", width: "100px" }
            },
            filters: {
              customer_name: { "operator" => "contains", "value" => "山田" }
            },
            sorts: ["delivery_date desc"]
          }
        }
      )
    end

    it "extracts settings for a table" do
      result = helper.rails_table_preference_params(params, table_key: :orders)

      expect(result).to include("columns", "filters", "sorts")
      expect(result["columns"]["customer_code"]).to include("visible" => false, "order" => 2, "width" => "12rem")
      expect(result["columns"]["customer_name"]).to include("visible" => true, "order" => 1)
      expect(result["columns"]).not_to have_key("missing_column")
      expect(result["filters"]).to eq({ "customer_name" => { "operator" => "contains", "value" => "山田" } })
      expect(result["sorts"]).to eq(["delivery_date desc"])
    end

    it "raises when table_key is missing" do
      expect do
        helper.rails_table_preference_params(params)
      end.to raise_error(ArgumentError, /table_key is required/)
    end

    it "returns an empty hash when params do not include table preferences" do
      empty_params = ActionController::Parameters.new({})

      expect(helper.rails_table_preference_params(empty_params, table_key: :orders)).to eq({})
    end

    it "handles missing filters and sorts" do
      params[:table_preferences][:orders].delete(:filters)
      params[:table_preferences][:orders].delete(:sorts)

      result = helper.rails_table_preference_params(params, table_key: :orders)

      expect(result["filters"]).to eq({})
      expect(result["sorts"]).to eq([])
    end
  end

  describe "#rails_table_preference_merged_params" do
    it "merges submitted settings with current column definitions" do
      existing = {
        "columns" => {
          "customer_code" => { "visible" => false, "order" => 2, "width" => "12rem" },
          "missing_column" => { "visible" => true, "order" => 99 }
        },
        "filters" => {
          "customer_name" => { "operator" => "contains", "value" => "山田" }
        },
        "sorts" => ["delivery_date desc"]
      }

      current_columns = [
        RailsTablePreferences::TableColumn.new(key: :customer_code, label: "顧客コード", visible: true, order: 1),
        RailsTablePreferences::TableColumn.new(key: :customer_name, label: "顧客名", visible: true, order: 2)
      ]

      result = helper.rails_table_preference_merged_params(existing, current_columns)

      expect(result["columns"]["customer_code"]).to include("visible" => false, "order" => 2)
      expect(result["columns"]["customer_name"]).to include("visible" => true, "order" => 2)
      expect(result["columns"]).not_to have_key("missing_column")
      expect(result["filters"]).to eq(existing["filters"])
      expect(result["sorts"]).to eq(existing["sorts"])
    end

    it "ignores malformed column entries" do
      result = helper.rails_table_preference_merged_params({ "columns" => { "customer_code" => "bad" } }, [])

      expect(result["columns"]).to eq({})
    end
  end

  describe "#table_preferences_hidden_fields" do
    it "renders hidden inputs for columns, filters, and sorts" do
      settings = {
        "columns" => {
          "customer_code" => { "visible" => "0", "order" => "2", "width" => "12rem" },
          "customer_name" => { "visible" => "1", "order" => "1" }
        },
        "filters" => {
          "customer_name" => { "operator" => "contains", "value" => "山田" }
        },
        "sorts" => ["delivery_date desc"]
      }

      html = helper.table_preferences_hidden_fields(settings, param_namespace: "q")

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
        expect(html).to include("テーブル初期設定に戻す")
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

    it "passes a localized delete confirmation and accessible label to the delete button" do
      I18n.with_locale(:ja) do
        html = helper.table_preferences_editor(table_key: :orders, columns: [:customer_code])

        expect(html).to include("rails-table-preferences-delete-confirm-label-value=\"この保存済み設定を削除します。よろしいですか？\"")
        expect(html).to include("title=\"この保存済み設定を削除します。よろしいですか？\"")
        expect(html).to include("aria-label=\"削除: この保存済み設定を削除します。よろしいですか？\"")
      end
    end

    it "renders a status region and localized async status labels" do
      I18n.with_locale(:ja) do
        html = helper.table_preferences_editor(table_key: :orders, columns: [:customer_code])

        expect(html).to include("rails-table-preferences-target=\"status\"")
        expect(html).to include('role="status"')
        expect(html).to include('aria-live="polite"')
        expect(html).to include('aria-label="保存状態"')
        expect(html).to include("rails-table-preferences-loading-status-label-value=\"設定を読み込み中です...\"")
        expect(html).to include("rails-table-preferences-operation-failed-status-label-value=\"設定の操作を完了できませんでした。\"")
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