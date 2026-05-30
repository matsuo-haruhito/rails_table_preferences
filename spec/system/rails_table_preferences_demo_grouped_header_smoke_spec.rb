# frozen_string_literal: true

require "spec_helper"

class RailsTablePreferencesGroupedHeaderSmokeOrdersController < ApplicationController
  DEMO_COLUMN_DEFINITIONS = [
    { "key" => "order_no", "label" => "受注番号", "group" => { "key" => "order", "label" => "受注情報" } },
    { "key" => "status", "label" => "状態", "group" => { "key" => "order", "label" => "受注情報" } },
    { "key" => "customer_name", "label" => "得意先名", "group" => { "key" => "customer", "label" => "得意先情報" } },
    { "key" => "delivery_date", "label" => "納品日", "group" => { "key" => "delivery", "label" => "配送情報" } },
    { "key" => "shipping_code", "label" => "配送コード", "group" => { "key" => "delivery", "label" => "配送情報" } },
    { "key" => "memo", "label" => "備考", "group" => { "key" => "delivery", "label" => "配送情報" } }
  ].freeze

  TEMPLATE = <<~ERB
    <h1>Rails Table Preferences Grouped Header Smoke</h1>

    <div class="rails-table-preferences-demo-scroll">
      <table class="table rails-table-preferences-demo-table">
        <thead>
          <% if @demo_visible_column_groups.any? %>
            <tr class="rails-table-preferences-demo-table__group-row">
              <% @demo_visible_column_groups.each do |group| %>
                <th colspan="<%= group["colspan"] %>"><%= group["label"] %></th>
              <% end %>
            </tr>
          <% end %>
          <tr>
            <% @demo_visible_columns.each do |column| %>
              <th data-rails-table-preferences-column-key="<%= column["key"] %>"><%= column["label"] %></th>
            <% end %>
          </tr>
        </thead>
        <tbody>
          <tr>
            <% @demo_visible_columns.each do |column| %>
              <td data-rails-table-preferences-column-key="<%= column["key"] %>"><%= column["label"] %></td>
            <% end %>
          </tr>
        </tbody>
      </table>
    </div>
  ERB

  def index
    settings = settings_for_layout(params[:saved_layout])
    @demo_visible_columns = demo_visible_columns(settings)
    @demo_visible_column_groups = demo_visible_column_groups(@demo_visible_columns)

    render inline: TEMPLATE, type: :erb
  end

  private

  def settings_for_layout(saved_layout)
    return delivery_focus_settings if saved_layout == "delivery_focus"

    {
      "columns" => [
        { "key" => "order_no", "visible" => true, "order" => 10 },
        { "key" => "status", "visible" => true, "order" => 20 },
        { "key" => "customer_name", "visible" => true, "order" => 30 },
        { "key" => "delivery_date", "visible" => true, "order" => 40 },
        { "key" => "shipping_code", "visible" => true, "order" => 50 },
        { "key" => "memo", "visible" => false, "order" => 60 }
      ]
    }
  end

  def delivery_focus_settings
    {
      "columns" => [
        { "key" => "order_no", "visible" => true, "order" => 10 },
        { "key" => "status", "visible" => false, "order" => 20 },
        { "key" => "customer_name", "visible" => false, "order" => 30 },
        { "key" => "delivery_date", "visible" => true, "order" => 40 },
        { "key" => "shipping_code", "visible" => true, "order" => 50 },
        { "key" => "memo", "visible" => false, "order" => 60 }
      ]
    }
  end

  def demo_visible_columns(settings)
    settings_by_key = settings.fetch("columns").index_by { |column| column.fetch("key") }

    DEMO_COLUMN_DEFINITIONS
      .filter_map do |column|
        settings_column = settings_by_key.fetch(column.fetch("key"), {})
        next if settings_column.fetch("visible", true) == false

        column.merge("order" => settings_column.fetch("order", 0))
      end
      .sort_by { |column| column.fetch("order") }
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
end

Rails.application.routes.disable_clear_and_finalize = true
Rails.application.routes.append do
  get "/rails_table_preferences_grouped_header_smoke/orders", to: "rails_table_preferences_grouped_header_smoke_orders#index"
end
Rails.application.reload_routes!

RSpec.describe "rails_table_preferences demo grouped header smoke", type: :system do
  def visit_grouped_header_smoke(saved_layout: nil)
    path = "/rails_table_preferences_grouped_header_smoke/orders"
    path = "#{path}?saved_layout=#{saved_layout}" if saved_layout

    visit path
  end

  def grouped_headers
    page.all("thead tr.rails-table-preferences-demo-table__group-row th", visible: :all).map do |cell|
      { "label" => cell.text, "colspan" => cell["colspan"].to_i }
    end
  end

  def leaf_header_keys
    page.all("th[data-rails-table-preferences-column-key]", visible: :all).map do |cell|
      cell["data-rails-table-preferences-column-key"]
    end
  end

  it "keeps grouped headers aligned with the default visible demo columns" do
    visit_grouped_header_smoke

    expect(leaf_header_keys).to eq(%w[order_no status customer_name delivery_date shipping_code])
    expect(grouped_headers).to eq([
      { "label" => "受注情報", "colspan" => 2 },
      { "label" => "得意先情報", "colspan" => 1 },
      { "label" => "配送情報", "colspan" => 2 }
    ])
    expect(grouped_headers.sum { |header| header.fetch("colspan") }).to eq(leaf_header_keys.length)
  end

  it "keeps grouped headers aligned after reloading a saved visible-column layout" do
    visit_grouped_header_smoke(saved_layout: "delivery_focus")

    expect(leaf_header_keys).to eq(%w[order_no delivery_date shipping_code])
    expect(grouped_headers).to eq([
      { "label" => "受注情報", "colspan" => 1 },
      { "label" => "配送情報", "colspan" => 2 }
    ])
    expect(grouped_headers.map { |header| header.fetch("label") }).not_to include("得意先情報")
    expect(grouped_headers.sum { |header| header.fetch("colspan") }).to eq(leaf_header_keys.length)
  end
end
