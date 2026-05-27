# frozen_string_literal: true

module RailsTablePreferencesDemo
  class OrdersController < ApplicationController
    helper RailsTablePreferences::TablePreferencesHelper
    include RailsTablePreferences::Controller
    include RailsTablePreferences::TablePreferencesHelper

    DEMO_TABLE_KEY = :rails_table_preferences_demo_orders
    SHARED_PRESET_NAME = "共有ビュー"
    ROLE_PRESET_NAME = "担当ビュー"
    DEMO_ROLE_KEY = "operations"

    def index
      ensure_demo_shared_preset!
      ensure_demo_role_preset!
      @table_columns = table_columns
      @table_preference_settings = rails_table_preference_settings(table_key: DEMO_TABLE_KEY)
      @export_payload_preview = RailsTablePreferences::ExportPayload.call(
        settings: @table_preference_settings,
        columns: @table_columns
      )

      preference_params = rails_table_preference_params(
        table_key: DEMO_TABLE_KEY,
        columns: @table_columns
      )

      @orders = apply_demo_params(demo_orders, params.to_unsafe_h.merge(preference_params))
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
        table_preferences_column(:memo, label: "備考", default_width: 260, default_truncate: 24),
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
          internal_cost: 8_000,
          memo: "午前指定。初回出荷のため伝票控えを同梱してください。"
        },
        {
          order_no: "A002",
          customer_name: "田中物流 関西センター",
          delivery_date: Date.current + 1.day,
          status: "出荷済",
          amount: 34_000,
          internal_cost: 21_000,
          memo: "午後着。パレット回収あり。列幅変更と省略表示の確認に使えます。"
        },
        {
          order_no: "A003",
          customer_name: "佐藤食品 冷凍倉庫",
          delivery_date: Date.current + 2.days,
          status: "保留",
          amount: 56_000,
          internal_cost: 39_000,
          memo: "温度帯確認待ち。ステータス絞り込みと並び替えの確認向けです。"
        },
        {
          order_no: "A004",
          customer_name: "東京医療機器",
          delivery_date: Date.current + 3.days,
          status: "未出荷",
          amount: 89_000,
          internal_cost: 63_000,
          memo: "東京都内向けの追加便。得意先名で「東京」を検索したときのヒット行です。"
        },
        {
          order_no: "A005",
          customer_name: "東京製菓",
          delivery_date: Date.current + 5.days,
          status: "出荷済",
          amount: 21_500,
          internal_cost: 14_000,
          memo: "備考をやや短めにして、同じ検索語でも表示差が分かるようにしています。"
        },
        {
          order_no: "A006",
          customer_name: "北星化学",
          delivery_date: Date.current + 7.days,
          status: "保留",
          amount: 104_000,
          internal_cost: 76_000,
          memo: "月末締め案件。shared preset と owner preset の切り替え時に列差分を見比べやすいサンプルです。"
        }
      ]
    end

    def apply_demo_params(orders, merged_params)
      filtered = orders
      search_word = merged_params["search_word"].presence || merged_params[:search_word]
      status = merged_params["status"].presence || merged_params[:status]
      from_delivery_date = parse_date(merged_params["from_delivery_date"].presence || merged_params[:from_delivery_date])
      to_delivery_date = parse_date(merged_params["to_delivery_date"].presence || merged_params[:to_delivery_date])

      filtered = filtered.select { |order| order[:customer_name].include?(search_word) } if search_word.present?
      filtered = filtered.select { |order| order[:status] == status } if status.present?
      filtered = filtered.select { |order| order[:delivery_date] >= from_delivery_date } if from_delivery_date
      filtered = filtered.select { |order| order[:delivery_date] <= to_delivery_date } if to_delivery_date

      sort_orders(filtered, merged_params["sort"].presence || merged_params[:sort])
    end

    def sort_orders(orders, sort)
      key = sort.to_s.delete_prefix("-").presence
      return orders unless key

      sorted = orders.sort_by { |order| order[key.to_sym] || "" }
      sort.to_s.start_with?("-") ? sorted.reverse : sorted
    end

    def parse_date(value)
      return if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def ensure_demo_shared_preset!
      preference = RailsTablePreferences::Preference.find_or_initialize_for(
        user: nil,
        table_key: DEMO_TABLE_KEY,
        name: SHARED_PRESET_NAME,
        scope_type: RailsTablePreferences::Preference::SHARED_SCOPE_TYPE
      )
      settings = shared_demo_preset_settings
      return if preference.persisted? && preference.settings == settings && preference.default_flag == false

      preference.settings = settings
      preference.default_flag = false
      preference.save!
    end

    def ensure_demo_role_preset!
      preference = RailsTablePreferences::Preference.find_or_initialize_for(
        user: nil,
        table_key: DEMO_TABLE_KEY,
        name: ROLE_PRESET_NAME,
        scope_type: RailsTablePreferences::Preference::ROLE_SCOPE_TYPE,
        scope_key: DEMO_ROLE_KEY
      )
      settings = role_demo_preset_settings
      return if preference.persisted? && preference.settings == settings && preference.default_flag == true

      preference.settings = settings
      preference.default_flag = true
      preference.save!
    end

    def shared_demo_preset_settings
      {
        "columns" => [
          { "key" => "order_no", "visible" => true, "order" => 10, "width" => 120 },
          { "key" => "status", "visible" => true, "order" => 20, "width" => 120 },
          { "key" => "customer_name", "visible" => true, "order" => 30, "width" => 240, "truncate" => 24 },
          { "key" => "delivery_date", "visible" => true, "order" => 40, "width" => 140 },
          { "key" => "amount", "visible" => true, "order" => 50, "width" => 120 },
          { "key" => "memo", "visible" => false, "order" => 60, "width" => 260, "truncate" => 24 }
        ],
        "filters" => {
          "status" => { "operator" => "in", "values" => ["未出荷", "保留"] }
        },
        "sorts" => [
          { "key" => "delivery_date", "direction" => "asc" }
        ]
      }
    end

    def role_demo_preset_settings
      {
        "columns" => [
          { "key" => "customer_name", "visible" => true, "order" => 10, "width" => 240, "truncate" => 24 },
          { "key" => "status", "visible" => true, "order" => 20, "width" => 120 },
          { "key" => "delivery_date", "visible" => true, "order" => 30, "width" => 140 },
          { "key" => "memo", "visible" => true, "order" => 40, "width" => 320, "truncate" => 40 },
          { "key" => "amount", "visible" => true, "order" => 50, "width" => 120 },
          { "key" => "order_no", "visible" => false, "order" => 60, "width" => 120 }
        ],
        "filters" => {},
        "sorts" => [
          { "key" => "amount", "direction" => "desc" }
        ]
      }
    end
  end
end
