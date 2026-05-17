# frozen_string_literal: true

module RailsTablePreferencesDemo
  class OrdersController < ApplicationController
    helper RailsTablePreferences::TablePreferencesHelper
    include RailsTablePreferences::Controller

    def index
      @table_columns = table_columns
      @table_preference_settings = rails_table_preference_settings(table_key: :rails_table_preferences_demo_orders)

      preference_params = rails_table_preference_params(
        table_key: :rails_table_preferences_demo_orders,
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
          customer_name: "山田商事",
          delivery_date: Date.current,
          status: "未出荷",
          amount: 12_000,
          internal_cost: 8_000,
          memo: "長い備考テキストの表示確認用です。列幅と省略表示を確認できます。"
        },
        {
          order_no: "A002",
          customer_name: "田中物流",
          delivery_date: Date.current + 1.day,
          status: "出荷済",
          amount: 34_000,
          internal_cost: 21_000,
          memo: "フィルター、ソート、列幅変更の確認に使うデモ行です。"
        },
        {
          order_no: "A003",
          customer_name: "佐藤食品",
          delivery_date: Date.current + 2.days,
          status: "保留",
          amount: 56_000,
          internal_cost: 39_000,
          memo: "ヘッダドラッグと表示項目の並び替えを確認します。"
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
  end
end
