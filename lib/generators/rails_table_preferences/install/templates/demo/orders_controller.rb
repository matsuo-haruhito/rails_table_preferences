# frozen_string_literal: true

module RailsTablePreferencesDemo
  class OrdersController < ApplicationController
    helper RailsTablePreferences::TablePreferencesHelper
    include RailsTablePreferences::Controller
    include RailsTablePreferences::TablePreferencesHelper

    DEMO_TABLE_KEY = :rails_table_preferences_demo_orders
    DEMO_ROLE_KEY = "operations"
    DEMO_ORGANIZATION_KEY = "tokyo"

    def index
      ensure_demo_presets!

      @table_columns = table_columns
      @demo_scope_context = demo_scope_context
      @table_preference_settings = rails_table_preference_settings(
        table_key: DEMO_TABLE_KEY,
        scope_context: @demo_scope_context
      )

      preference_params = rails_table_preference_params(
        table_key: DEMO_TABLE_KEY,
        columns: @table_columns,
        scope_context: @demo_scope_context
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
          customer_name: "山田商事",
          delivery_date: Date.current,
          status: "未出荷",
          amount: 12_000,
          internal_cost: 8_000,
          memo: "午前指定。月末締めの定番受注として、owner preset の絞り込み確認に使えます。"
        },
        {
          order_no: "A002",
          customer_name: "田中物流",
          delivery_date: Date.current + 1.day,
          status: "出荷済",
          amount: 34_000,
          internal_cost: 21_000,
          memo: "午後便で出荷済み。短めの備考として、省略表示との見比べに使えます。"
        },
        {
          order_no: "A003",
          customer_name: "佐藤食品",
          delivery_date: Date.current + 2.days,
          status: "保留",
          amount: 56_000,
          internal_cost: 39_000,
          memo: "原料確認待ち。保留行として status filter と preset 切り替えの差分確認に使います。"
        },
        {
          order_no: "A004",
          customer_name: "鈴木物産",
          delivery_date: Date.current + 3.days,
          status: "未出荷",
          amount: 98_500,
          internal_cost: 71_400,
          memo: "冷蔵便予定。金額が大きめなので amount sort と列幅 auto-fit の確認に向いています。"
        },
        {
          order_no: "A005",
          customer_name: "中央メディカル",
          delivery_date: Date.current - 1.day,
          status: "出荷済",
          amount: 7_800,
          internal_cost: 4_600,
          memo: "追加伝票なし。少額かつ最短納期の例として、date sort と amount sort の差分が見えます。"
        },
        {
          order_no: "A006",
          customer_name: "東西パーツ",
          delivery_date: Date.current + 5.days,
          status: "保留",
          amount: 142_000,
          internal_cost: 101_000,
          memo: "工程再確認中。長めの備考なので truncate と wrap の使い分けを見比べやすくしています。"
        }
      ]
    end

    def ensure_demo_presets!
      owner = rails_table_preferences_current_owner
      return unless owner

      ensure_owner_demo_preset!(owner)
      ensure_shared_demo_preset!
      ensure_role_demo_preset!
      ensure_organization_demo_preset!
    end

    def ensure_owner_demo_preset!(owner)
      preset = RailsTablePreferences::Preference.find_or_initialize_for(
        user: owner,
        table_key: DEMO_TABLE_KEY,
        name: "owner-compact"
      )
      return unless preset.new_record?

      preset.settings = {
        columns: [
          { key: "order_no", visible: true, order: 10, width: 120 },
          { key: "customer_name", visible: true, order: 20, width: 200, truncate: 20 },
          { key: "status", visible: true, order: 30, width: 110 },
          { key: "amount", visible: true, order: 40, width: 120 },
          { key: "delivery_date", visible: false, order: 50, width: 140 },
          { key: "memo", visible: false, order: 60, width: 260, truncate: 24 }
        ]
      }
      preset.default_flag = false
      preset.save!
    end

    def ensure_shared_demo_preset!
      preset = RailsTablePreferences::Preference.find_or_initialize_for(
        user: nil,
        table_key: DEMO_TABLE_KEY,
        name: "shared-baseline",
        scope_type: RailsTablePreferences::Preference::SHARED_SCOPE_TYPE
      )
      return unless preset.new_record?

      preset.settings = {
        columns: [
          { key: "order_no", visible: true, order: 10, width: 120 },
          { key: "customer_name", visible: true, order: 20, width: 240, truncate: 24 },
          { key: "delivery_date", visible: true, order: 30, width: 140 },
          { key: "status", visible: true, order: 40, width: 120 },
          { key: "amount", visible: true, order: 50, width: 120 },
          { key: "memo", visible: false, order: 60, width: 260, truncate: 24 }
        ]
      }
      preset.default_flag = false
      preset.save!
    end

    def ensure_role_demo_preset!
      preset = RailsTablePreferences::Preference.find_or_initialize_for(
        user: nil,
        table_key: DEMO_TABLE_KEY,
        name: "operations-default",
        scope_type: RailsTablePreferences::Preference::ROLE_SCOPE_TYPE,
        scope_key: DEMO_ROLE_KEY
      )
      return unless preset.new_record?

      preset.settings = {
        columns: [
          { key: "order_no", visible: true, order: 10, width: 120 },
          { key: "customer_name", visible: true, order: 20, width: 240, truncate: 24 },
          { key: "status", visible: true, order: 30, width: 120 },
          { key: "delivery_date", visible: true, order: 40, width: 140 },
          { key: "memo", visible: true, order: 50, width: 260, truncate: 24 },
          { key: "amount", visible: false, order: 60, width: 120 }
        ]
      }
      preset.default_flag = true
      preset.save!
    end

    def ensure_organization_demo_preset!
      preset = RailsTablePreferences::Preference.find_or_initialize_for(
        user: nil,
        table_key: DEMO_TABLE_KEY,
        name: "tokyo-default",
        scope_type: RailsTablePreferences::Preference::ORGANIZATION_SCOPE_TYPE,
        scope_key: DEMO_ORGANIZATION_KEY
      )
      return unless preset.new_record?

      preset.settings = {
        columns: [
          { key: "order_no", visible: true, order: 10, width: 120 },
          { key: "customer_name", visible: true, order: 20, width: 220, truncate: 18 },
          { key: "delivery_date", visible: true, order: 30, width: 140 },
          { key: "amount", visible: true, order: 40, width: 120 },
          { key: "status", visible: false, order: 50, width: 120 },
          { key: "memo", visible: false, order: 60, width: 260, truncate: 24 }
        ]
      }
      preset.default_flag = true
      preset.save!
    end

    def demo_scope_context
      {
        roles: [DEMO_ROLE_KEY],
        organization: DEMO_ORGANIZATION_KEY
      }
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
  end
end