# frozen_string_literal: true

module RailsTablePreferencesDemo
  class OrdersController < ApplicationController
    helper RailsTablePreferences::TablePreferencesHelper
    include RailsTablePreferences::Controller
    include RailsTablePreferences::TablePreferencesHelper

    DEMO_TABLE_KEY = :rails_table_preferences_demo_orders
    SHARED_PRESET_NAME = "共有ビュー"

    def index
      ensure_demo_shared_preset!
      @table_columns = table_columns
      @table_preference_settings = rails_table_preference_settings(table_key: DEMO_TABLE_KEY)

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
          internal_cost: 8_000,
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
          internal_cost: 21_000,
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
          internal_cost: 39_000,
          memo: "ステータス絞り込みと並び替えの確認向けです。"
        },
        {
          order_no: "A004",
          customer_name: "東京医療機器",
          delivery_date: Date.current + 3.days,
          status: "未出荷",
          amount: 89_000,
          shipping_code: "TOKYO-MEDICAL-RUSH-410",
          shipping_notes: "東京都内向けの追加便です。午後の短い時間帯しか受け取りできないため、到着前の電話連絡が必要です。",
          internal_cost: 63_000,
          memo: "得意先名で「東京」を検索したときのヒット行です。"
        },
        {
          order_no: "A005",
          customer_name: "東京製菓",
          delivery_date: Date.current + 5.days,
          status: "出荷済",
          amount: 21_500,
          shipping_code: "TOKYO-SWEETS-WEEKLY-088",
          shipping_notes: "定期便。納品口は狭いですが荷受け自体は短時間で終わるため、積み下ろし手順のメモが折り返して表示される列です。",
          internal_cost: 14_000,
          memo: "備考をやや短めにして、同じ検索語でも表示差が分かるようにしています。"
        },
        {
          order_no: "A006",
          customer_name: "北星化学",
          delivery_date: Date.current + 7.days,
          status: "保留",
          amount: 104_000,
          shipping_code: "HOKUSEI-MONTH-END-HOLD-512",
          shipping_notes: "月末締め案件。shared preset と owner preset の切り替え時に列差分を見比べやすいよう、もっとも長い配送メモを入れています。",
          internal_cost: 76_000,
          memo: "shared preset と owner preset の切り替え時に列差分を見比べやすいサンプルです。"
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

    def shared_demo_preset_settings
      {
        "columns" => [
          { "key" => "order_no", "visible" => true, "order" => 10, "width" => 120 },
          { "key" => "status", "visible" => true, "order" => 20, "width" => 120 },
          { "key" => "customer_name", "visible" => true, "order" => 30, "width" => 240, "truncate" => 24 },
          { "key" => "delivery_date", "visible" => true, "order" => 40, "width" => 140 },
          { "key" => "amount", "visible" => true, "order" => 50, "width" => 120 },
          { "key" => "shipping_code", "visible" => true, "order" => 60, "width" => 140, "overflow" => "nowrap" },
          { "key" => "shipping_notes", "visible" => true, "order" => 70, "width" => 160, "overflow" => "wrap" },
          { "key" => "memo", "visible" => false, "order" => 80, "width" => 180, "truncate" => 24 }
        ],
        "filters" => {
          "status" => { "operator" => "in", "values" => ["未出荷", "保留"] }
        },
        "sorts" => [
          { "key" => "delivery_date", "direction" => "asc" }
        ]
      }
    end
  end
end
