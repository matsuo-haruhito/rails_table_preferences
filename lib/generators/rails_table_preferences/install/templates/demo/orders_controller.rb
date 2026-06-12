# frozen_string_literal: true

module RailsTablePreferencesDemo
  class OrdersController < ApplicationController
    helper RailsTablePreferences::TablePreferencesHelper
    include RailsTablePreferences::Controller
    include RailsTablePreferences::TablePreferencesHelper

    DEMO_TABLE_KEY = :rails_table_preferences_demo_orders
    SHARED_PRESET_NAME = "共有ビュー"
    ROLE_PRESET_NAME = "担当ビュー"
    ORGANIZATION_PRESET_NAME = "東京組織ビュー"
    DEMO_ROLE_KEY = "operations"
    DEMO_ORGANIZATION_KEY = "tokyo-hq"
    DEMO_SCOPE_CONTEXT_PARAM = "demo_scope_context"
    DEMO_SCOPE_CONTEXT_HOST_MODE = "host"
    DEMO_SCOPE_CONTEXT_MODE_CONFIGS = {
      DEMO_SCOPE_CONTEXT_HOST_MODE => {
        "label" => "Host app context",
        "description" => "Use the host app's current scope_context_method result."
      },
      "owner" => {
        "label" => "Owner-only baseline",
        "description" => "Clear scoped keys and compare the shared baseline.",
        "context" => {}
      },
      "role" => {
        "label" => "Role preset lane",
        "description" => "Force roles: [operations] to verify the role preset lane.",
        "context" => { "roles" => [DEMO_ROLE_KEY] }
      },
      "organization" => {
        "label" => "Organization preset lane",
        "description" => "Force organization: tokyo-hq with no matching role default.",
        "context" => { "organization" => DEMO_ORGANIZATION_KEY }
      }
    }.freeze
    DEMO_OWNER_PARAM = "demo_owner"
    DEMO_OWNER_SWITCH_LABELS = ["Demo owner A", "Demo owner B"].freeze
    DEMO_BASELINE_QUERY_PARAMS = [DEMO_OWNER_PARAM, DEMO_SCOPE_CONTEXT_PARAM].freeze

    owner_method_name = RailsTablePreferences.configuration.current_user_method.to_s.presence || "current_user"
    define_method(owner_method_name) do
      override = demo_owner_override
      return override if override

      super_method = method(owner_method_name).super_method
      return super_method.call if super_method

      nil
    end

    def index
      ensure_demo_shared_preset!
      ensure_demo_role_preset!
      ensure_demo_organization_preset!
      @table_columns = table_columns
      @table_preference_settings = rails_table_preference_settings(table_key: DEMO_TABLE_KEY)
      @demo_table_state = table_preferences_state(settings: @table_preference_settings, columns: @table_columns)
      @demo_visible_columns = @demo_table_state.fetch("visible_columns")
      @demo_visible_column_groups = demo_visible_column_groups(@demo_visible_columns)
      @demo_owner_switches = demo_owner_switches
      @demo_owner_switch_ready = @demo_owner_switches.length > 1
      @demo_scope_context_switches = demo_scope_context_switches
      @demo_scope_context_toggle_ready = demo_scope_context_toggle_ready?
      @demo_scope_context_summary = demo_scope_context_summary
      @export_payload_preview = RailsTablePreferences::ExportPayload.call(
        settings: @table_preference_settings,
        columns: @table_columns
      )
      @demo_owner_summary = demo_owner_summary

      preference_params = rails_table_preference_params(
        table_key: DEMO_TABLE_KEY,
        columns: @table_columns
      )

      @orders = apply_demo_params(demo_orders, params.to_unsafe_h.merge(preference_params))
    end

    private

    def table_preference_scope_context
      override_context = demo_scope_context_override
      return override_context if override_context

      return super if defined?(super)

      {}
    end

    def demo_owner_summary
      owner = demo_current_owner

      {
        "model_name" => demo_owner_model_name(owner),
        "display_name" => demo_owner_display_name(owner),
        "identifier" => demo_owner_identifier(owner)
      }
    end

    def demo_current_owner
      method_name = RailsTablePreferences.configuration.current_user_method.to_s.presence || "current_user"
      return unless respond_to?(method_name, true)

      send(method_name)
    rescue NoMethodError
      nil
    end

    def demo_host_app_owner
      method_name = RailsTablePreferences.configuration.current_user_method.to_s.presence || "current_user"
      super_method = method(method_name).super_method
      return super_method.call if super_method

      nil
    rescue NameError, NoMethodError
      nil
    end

    def demo_owner_model_name(owner)
      return "Not available" if owner.blank?

      if owner.class.respond_to?(:model_name)
        owner.class.model_name.human
      else
        owner.class.name
      end
    end

    def demo_owner_display_name(owner)
      return "Not available" if owner.blank?

      %i[display_name name title email].each do |method_name|
        next unless owner.respond_to?(method_name)

        value = owner.public_send(method_name)
        return value.to_s if value.present?
      end

      value = owner.to_s
      return value if value.present? && !value.start_with?("#<")

      "#{demo_owner_model_name(owner)} record"
    end

    def demo_owner_identifier(owner)
      return "Not available" if owner.blank?

      if owner.respond_to?(:id) && owner.id.present?
        "id: #{owner.id}"
      elsif owner.respond_to?(:to_param) && owner.to_param.present?
        owner.to_param.to_s
      else
        "Not available"
      end
    end

    def demo_owner_switches
      demo_available_owner_records.each_with_index.map do |owner, index|
        {
          "active" => demo_current_owner_switch_key == demo_owner_switch_key(owner),
          "description" => demo_owner_switch_description(owner, index),
          "label" => demo_owner_switch_label(index),
          "path" => demo_owner_switch_path(owner, index)
        }
      end
    end

    def demo_current_owner_switch_key
      demo_owner_switch_key(demo_current_owner)
    end

    def demo_owner_switch_key(owner)
      return "" if owner.blank?

      if owner.respond_to?(:id) && owner.id.present?
        owner.id.to_s
      else
        owner.object_id.to_s
      end
    end

    def demo_owner_override
      selected_key = params[DEMO_OWNER_PARAM].to_s.presence
      return if selected_key.blank?

      demo_available_owner_records.find { |owner| demo_owner_switch_key(owner) == selected_key }
    end

    def demo_available_owner_records
      @demo_available_owner_records ||= begin
        host_owner = demo_host_app_owner
        if host_owner.blank?
          []
        else
          owners = [host_owner]
          owners.concat(demo_existing_owner_candidates(host_owner))
          DEMO_OWNER_SWITCH_LABELS.each_index do |index|
            break if owners.length >= 3

            demo_owner = demo_find_or_create_owner_record(host_owner.class, index)
            owners << demo_owner if demo_owner.present?
          end
          owners.compact.uniq { |owner| demo_owner_switch_key(owner) }
        end
      end
    end

    def demo_existing_owner_candidates(host_owner)
      model = host_owner.class
      return [] unless defined?(ActiveRecord::Base) && model < ActiveRecord::Base

      scope = model.all
      scope = scope.where.not(id: host_owner.id) if host_owner.respond_to?(:id) && host_owner.id.present?
      scope.limit(2).to_a
    rescue StandardError
      []
    end

    def demo_find_or_create_owner_record(model, index)
      return unless defined?(ActiveRecord::Base) && model < ActiveRecord::Base

      attributes = demo_owner_seed_attributes(model, index)
      record = demo_owner_lookup_record(model, attributes) || model.new

      attributes.each do |attribute, value|
        setter = "#{attribute}="
        next unless record.respond_to?(setter)
        next if record.public_send(attribute).present?

        record.public_send(setter, value)
      end

      record.save! if record.new_record? || record.changed?
      record
    rescue StandardError
      nil
    end

    def demo_owner_lookup_record(model, attributes)
      lookup_attribute = %w[email slug code name].find do |attribute|
        attributes[attribute].present? && model.column_names.include?(attribute)
      end
      return unless lookup_attribute

      model.find_or_initialize_by(lookup_attribute => attributes.fetch(lookup_attribute))
    end

    def demo_owner_seed_attributes(model, index)
      label = DEMO_OWNER_SWITCH_LABELS.fetch(index)
      slug = label.downcase.tr(" ", "-")
      columns = model.column_names
      attributes = {}

      attributes["name"] = label if columns.include?("name")
      attributes["email"] = "#{slug}@example.test" if columns.include?("email")
      attributes["title"] = label if columns.include?("title")
      attributes["slug"] = slug if columns.include?("slug")
      attributes["code"] = slug if columns.include?("code")
      attributes
    end

    def demo_owner_switch_label(index)
      return "Host app owner" if index.zero?

      DEMO_OWNER_SWITCH_LABELS.fetch(index - 1)
    end

    def demo_owner_switch_description(owner, index)
      return "Use the owner returned by the host app's configured current-user method." if index.zero?

      "Switch to #{demo_owner_display_name(owner)} and confirm presets stay isolated from the other owners."
    end

    def demo_owner_switch_path(owner, index)
      query_params = demo_baseline_query_params.except(DEMO_OWNER_PARAM)
      query_params = query_params.merge(DEMO_OWNER_PARAM => demo_owner_switch_key(owner)) unless index.zero?
      return request.path if query_params.empty?

      "#{request.path}?#{query_params.to_query}"
    end

    def demo_baseline_query_params
      request.query_parameters.slice(*DEMO_BASELINE_QUERY_PARAMS)
    end

    def table_columns
      [
        table_preferences_column(
          :order_no,
          label: "受注番号",
          default_width: 140,
          pinned: true,
          group: { key: :order, label: "受注情報" },
          sortable: true
        ),
        table_preferences_column(
          :customer_name,
          label: "得意先名",
          export_key: :customer_display_name,
          default_width: 240,
          default_truncate: 24,
          group: { key: :customer, label: "得意先情報" },
          filter: { type: :text, param: :search_word },
          sortable: true
        ),
        table_preferences_column(
          :delivery_date,
          label: "納品日",
          default_width: 140,
          group: { key: :delivery, label: "配送情報" },
          filter: { type: :date, from_param: :from_delivery_date, to_param: :to_delivery_date },
          sortable: true
        ),
        table_preferences_column(
          :status,
          label: "状態",
          default_width: 120,
          group: { key: :order, label: "受注情報" },
          filter: { type: :select, param: :status, options: ["未出荷", "出荷済", "保留"] },
          sortable: true
        ),
        table_preferences_column(
          :confirmed,
          label: "確認済",
          default_width: 100,
          group: { key: :order, label: "受注情報" },
          filter: { type: :boolean, param: :confirmed },
          sortable: true
        ),
        table_preferences_column(
          :amount,
          label: "金額",
          default_width: 120,
          group: { key: :order, label: "受注情報" },
          filter: { type: :number, param: :amount },
          sortable: true
        ),
        table_preferences_column(
          :shipping_code,
          label: "配送コード",
          default_width: 140,
          group: { key: :delivery, label: "配送情報" },
          overflow: "nowrap"
        ),
        table_preferences_column(
          :shipping_notes,
          label: "配送メモ",
          default_width: 160,
          group: { key: :delivery, label: "配送情報" },
          overflow: "wrap"
        ),
        table_preferences_column(
          :memo,
          label: "備考",
          default_width: 180,
          default_truncate: 24,
          group: { key: :delivery, label: "配送情報" }
        ),
        table_preferences_column(:internal_cost, label: "内部原価", ignored: true)
      ]
    end

    def demo_visible_column_groups(visible_columns)
      visible_columns
        .chunk { |column| demo_column_group(column) }
        .filter_map do |group, grouped_columns|
          next if group["label"].blank?

          group.merge(
            "columns" => grouped_columns,
            "colspan" => grouped_columns.length
          )
        end
    end

    def demo_column_group(column)
      group = column["group"] || column[:group]
      return { "key" => "", "label" => "" } if group.blank?

      case group
      when Hash
        stringified = group.deep_stringify_keys
        {
          "key" => stringified.fetch("key", stringified.fetch("label", "")).to_s,
          "label" => stringified.fetch("label", stringified.fetch("key", "")).to_s
        }
      else
        { "key" => group.to_s, "label" => group.to_s }
      end
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
          internal_cost: 8_000,
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
          internal_cost: 21_000,
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
          internal_cost: 39_000,
          memo: "ステータス絞り込みと並び替えの確認向けです。"
        },
        {
          order_no: "A004",
          customer_name: "東京医療機器",
          delivery_date: Date.current + 3.days,
          status: "未出荷",
          confirmed: true,
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
          confirmed: false,
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
          confirmed: false,
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
      confirmed = merged_params["confirmed"].presence || merged_params[:confirmed]
      amount = parse_amount(merged_params["amount"].presence || merged_params[:amount])
      from_amount = parse_amount(merged_params["from_amount"].presence || merged_params[:from_amount])
      to_amount = parse_amount(merged_params["to_amount"].presence || merged_params[:to_amount])
      from_delivery_date = parse_date(merged_params["from_delivery_date"].presence || merged_params[:from_delivery_date])
      to_delivery_date = parse_date(merged_params["to_delivery_date"].presence || merged_params[:to_delivery_date])

      filtered = filtered.select { |order| order[:customer_name].include?(search_word) } if search_word.present?
      filtered = filtered.select { |order| order[:status] == status } if status.present?
      filtered = filter_by_confirmed(filtered, confirmed)
      filtered = filtered.select { |order| order[:amount].to_f == amount } if amount
      filtered = filtered.select { |order| order[:amount].to_f >= from_amount } if from_amount
      filtered = filtered.select { |order| order[:amount].to_f <= to_amount } if to_amount
      filtered = filtered.select { |order| order[:delivery_date] >= from_delivery_date } if from_delivery_date
      filtered = filtered.select { |order| order[:delivery_date] <= to_delivery_date } if to_delivery_date

      sort_orders(filtered, merged_params["sort"].presence || merged_params[:sort])
    end

    def filter_by_confirmed(orders, confirmed)
      case confirmed.to_s
      when "true", "1", "yes", "はい"
        orders.select { |order| order[:confirmed] == true }
      when "false", "0", "no", "いいえ"
        orders.select { |order| order[:confirmed] == false }
      else
        orders
      end
    end

    def sort_orders(orders, sort)
      key = sort.to_s.delete_prefix("-").presence
      return orders unless key

      sorted = orders.sort_by { |order| order[key.to_sym] || "" }
      sort.to_s.start_with?("-") ? sorted.reverse : sorted
    end

    def parse_amount(value)
      return if value.blank?

      Float(value.to_s.delete(","))
    rescue ArgumentError, TypeError
      nil
    end

    def parse_date(value)
      return if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def demo_scope_context_switches
      DEMO_SCOPE_CONTEXT_MODE_CONFIGS.map do |mode, config|
        {
          "active" => demo_scope_context_mode == mode,
          "description" => config.fetch("description"),
          "label" => config.fetch("label"),
          "path" => demo_scope_context_switch_path(mode)
        }
      end
    end

    def demo_scope_context_toggle_ready?
      RailsTablePreferences.configuration.scope_context_method.to_s == "table_preference_scope_context"
    end

    def demo_scope_context_summary
      context = current_demo_scope_context
      roles = Array(context["roles"]).filter_map { |role| role.to_s.presence }
      organization = context["organization"].to_s.presence

      {
        "owner_only" => roles.empty? && organization.blank?,
        "roles" => roles,
        "organization" => organization
      }
    end

    def current_demo_scope_context
      method_name = RailsTablePreferences.configuration.scope_context_method
      return {} if method_name.blank? || !respond_to?(method_name, true)

      context = send(method_name)
      return {} unless context.is_a?(Hash)

      context.deep_stringify_keys
    end

    def demo_scope_context_mode
      mode = params[DEMO_SCOPE_CONTEXT_PARAM].to_s
      return mode if DEMO_SCOPE_CONTEXT_MODE_CONFIGS.key?(mode)

      DEMO_SCOPE_CONTEXT_HOST_MODE
    end

    def demo_scope_context_override
      mode = demo_scope_context_mode
      return unless DEMO_SCOPE_CONTEXT_MODE_CONFIGS.fetch(mode).key?("context")

      DEMO_SCOPE_CONTEXT_MODE_CONFIGS.fetch(mode).fetch("context").deep_dup
    end

    def demo_scope_context_switch_path(mode)
      query_params = demo_baseline_query_params.except(DEMO_SCOPE_CONTEXT_PARAM)
      query_params = query_params.merge(DEMO_SCOPE_CONTEXT_PARAM => mode) unless mode == DEMO_SCOPE_CONTEXT_HOST_MODE
      return request.path if query_params.empty?

      "#{request.path}?#{query_params.to_query}"
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

    def ensure_demo_organization_preset!
      preference = RailsTablePreferences::Preference.find_or_initialize_for(
        user: nil,
        table_key: DEMO_TABLE_KEY,
        name: ORGANIZATION_PRESET_NAME,
        scope_type: RailsTablePreferences::Preference::ORGANIZATION_SCOPE_TYPE,
        scope_key: DEMO_ORGANIZATION_KEY
      )
      settings = organization_demo_preset_settings
      return if preference.persisted? && preference.settings == settings && preference.default_flag == true

      preference.settings = settings
      preference.default_flag = true
      preference.save!
    end

    def shared_demo_preset_settings
      {
        "columns" => [
          { "key" => "order_no", "visible" => true, "order" => 10, "width" => 140, "pinned" => true },
          { "key" => "status", "visible" => true, "order" => 20, "width" => 120 },
          { "key" => "confirmed", "visible" => true, "order" => 30, "width" => 100 },
          { "key" => "amount", "visible" => true, "order" => 40, "width" => 120 },
          { "key" => "customer_name", "visible" => true, "order" => 50, "width" => 240, "truncate" => 24 },
          { "key" => "delivery_date", "visible" => true, "order" => 60, "width" => 140 },
          { "key" => "shipping_code", "visible" => true, "order" => 70, "width" => 140, "overflow" => "nowrap" },
          { "key" => "shipping_notes", "visible" => true, "order" => 80, "width" => 160, "overflow" => "wrap" },
          { "key" => "memo", "visible" => false, "order" => 90, "width" => 180, "truncate" => 24 }
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
          { "key" => "order_no", "visible" => true, "order" => 10, "width" => 140, "pinned" => true },
          { "key" => "customer_name", "visible" => true, "order" => 20, "width" => 240, "truncate" => 24 },
          { "key" => "delivery_date", "visible" => true, "order" => 30, "width" => 140 },
          { "key" => "status", "visible" => true, "order" => 40, "width" => 120 },
          { "key" => "confirmed", "visible" => true, "order" => 50, "width" => 100 },
          { "key" => "shipping_notes", "visible" => true, "order" => 60, "width" => 240, "overflow" => "wrap" },
          { "key" => "shipping_code", "visible" => true, "order" => 70, "width" => 140, "overflow" => "nowrap" },
          { "key" => "memo", "visible" => true, "order" => 80, "width" => 320, "truncate" => 40 },
          { "key" => "amount", "visible" => true, "order" => 90, "width" => 120 }
        ],
        "filters" => {},
        "sorts" => [
          { "key" => "amount", "direction" => "desc" }
        ]
      }
    end

    def organization_demo_preset_settings
      {
        "columns" => [
          { "key" => "customer_name", "visible" => true, "order" => 10, "width" => 240, "truncate" => 24 },
          { "key" => "delivery_date", "visible" => true, "order" => 20, "width" => 140 },
          { "key" => "order_no", "visible" => true, "order" => 30, "width" => 140, "pinned" => true },
          { "key" => "shipping_notes", "visible" => true, "order" => 40, "width" => 240, "overflow" => "wrap" },
          { "key" => "memo", "visible" => true, "order" => 50, "width" => 320, "truncate" => 32 },
          { "key" => "status", "visible" => true, "order" => 60, "width" => 120 },
          { "key" => "confirmed", "visible" => true, "order" => 70, "width" => 100 },
          { "key" => "shipping_code", "visible" => false, "order" => 80, "width" => 140, "overflow" => "nowrap" },
          { "key" => "amount", "visible" => false, "order" => 90, "width" => 120 }
        ],
        "filters" => {},
        "sorts" => [
          { "key" => "delivery_date", "direction" => "desc" }
        ]
      }
    end
  end
end
