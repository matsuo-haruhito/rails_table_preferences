# frozen_string_literal: true

require "spec_helper"

class RailsTablePreferencesEditorLayoutSmokeController < ApplicationController
  helper RailsTablePreferences::TablePreferencesHelper
  include RailsTablePreferences::TablePreferencesHelper

  EDITOR_CSS = File.read(File.expand_path("../../app/assets/stylesheets/rails_table_preferences.css", __dir__))

  TEMPLATE = <<~ERB
    <style>
      <%= RailsTablePreferencesEditorLayoutSmokeController::EDITOR_CSS %>
      body {
        margin: 0;
        font-family: system-ui, sans-serif;
      }
      .editor-layout-smoke-shell {
        max-width: 100%;
        padding: 1rem;
      }
    </style>

    <main class="editor-layout-smoke-shell">
      <%= table_preferences_editor(
        table_key: :editor_layout_smoke_orders,
        name: "default",
        title: "受注一覧の表示設定",
        editor_instance_key: "layout-smoke",
        columns: @columns
      ) %>
    </main>
  ERB

  def index
    @columns = [
      table_preferences_column(:order_no, label: "受注番号", default_width: 120),
      table_preferences_column(:customer_name, label: "非常に長い得意先名と部門名を含む列ラベル", default_width: 240, default_truncate: 24),
      table_preferences_column(:delivery_date, label: "納品予定日", default_width: 140),
      table_preferences_column(:status, label: "現在の処理ステータス", default_width: 160),
      table_preferences_column(:shipping_notes, label: "配送時の長い注意事項", default_width: 180, default_overflow: "wrap")
    ]

    render inline: TEMPLATE, type: :erb
  end
end

Rails.application.routes.disable_clear_and_finalize = true
Rails.application.routes.append do
  get "/rails_table_preferences_editor_layout_smoke", to: "rails_table_preferences_editor_layout_smoke#index"
end
Rails.application.reload_routes!

RSpec.describe "rails_table_preferences editor layout", type: :system, js: true do
  def resize_to(width, height = 900)
    page.driver.browser.manage.window.resize_to(width, height)
  end

  def layout_metrics
    page.evaluate_script(<<~JS)
      (() => {
        const viewportWidth = document.documentElement.clientWidth
        const documentWidth = document.documentElement.scrollWidth
        const editor = document.querySelector(".rails-table-preferences-editor")
        const maintenanceGroup = document.querySelector(".rails-table-preferences-editor__action-group--maintenance")
        const actionRow = document.querySelector(".rails-table-preferences-editor__actions")
        const visibleControls = Array.from(document.querySelectorAll(".rails-table-preferences-editor__actions button, .rails-table-preferences-editor__hint, .rails-table-preferences-editor__title"))
          .filter((element) => element.offsetParent !== null)
          .map((element) => {
            const rect = element.getBoundingClientRect()
            return {
              selector: element.className || element.textContent.trim(),
              left: rect.left,
              right: rect.right,
              width: rect.width,
              height: rect.height
            }
          })

        const maintenanceStyle = window.getComputedStyle(maintenanceGroup)

        return {
          viewportWidth,
          documentWidth,
          editorRight: editor.getBoundingClientRect().right,
          actionRowHeight: actionRow.getBoundingClientRect().height,
          maintenanceBorderTop: maintenanceStyle.borderTopWidth,
          maintenanceBorderLeft: maintenanceStyle.borderLeftWidth,
          visibleControls
        }
      })()
    JS
  end

  def expect_no_clipped_editor_controls(metrics)
    expect(metrics.fetch("documentWidth")).to be <= metrics.fetch("viewportWidth") + 1
    expect(metrics.fetch("editorRight")).to be <= metrics.fetch("viewportWidth") + 1
    expect(metrics.fetch("actionRowHeight")).to be > 0

    metrics.fetch("visibleControls").each do |control|
      expect(control.fetch("left")).to be >= 0
      expect(control.fetch("right")).to be <= metrics.fetch("viewportWidth") + 1
      expect(control.fetch("width")).to be > 0
      expect(control.fetch("height")).to be > 0
    end
  end

  [576, 416].each do |width|
    it "keeps editor title, hints, and maintenance actions visible at #{width}px" do
      resize_to(width)
      visit "/rails_table_preferences_editor_layout_smoke"

      expect(page).to have_css(".rails-table-preferences-editor[role='region'][aria-labelledby]")
      expect(page).to have_css(".rails-table-preferences-editor__title", text: "受注一覧の表示設定")
      expect(page).to have_css(".rails-table-preferences-editor__hint--maintenance", text: "Delete and reset")

      metrics = layout_metrics
      expect_no_clipped_editor_controls(metrics)
      expect(metrics.fetch("maintenanceBorderTop")).not_to eq("0px")
      expect(metrics.fetch("maintenanceBorderLeft")).to eq("0px")
    end
  end
end
