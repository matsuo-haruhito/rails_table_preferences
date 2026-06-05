# frozen_string_literal: true

require "spec_helper"

RSpec.describe "default CSS forced-colors friendly signals" do
  let(:css_path) do
    File.expand_path("../../app/assets/stylesheets/rails_table_preferences.css", __dir__)
  end

  let(:css) { File.read(css_path) }

  def rule_body(selector)
    match = css.match(/#{Regexp.escape(selector)}\s*\{(?<body>.*?)\n\}/m)
    expect(match).not_to be_nil

    match[:body]
  end

  it "keeps filter panel colors tied to system color keywords" do
    body = rule_body(".rails-table-preferences-filter-panel")

    expect(body).to include("border: 1px solid currentColor;")
    expect(body).to include("background: canvas;")
    expect(body).to include("color: canvastext;")
    expect(body).to include("max-width: min(24rem, calc(100vw - 2rem));")
  end

  it "keeps focus and active state cues visible without fixed theme colors" do
    resize_focus = rule_body(".rails-table-preferences-resize-handle:focus-visible")
    active_filter = rule_body(".rails-table-preferences-filter-button--active")
    sorted_header = rule_body(".rails-table-preferences-sortable-column--sorted")

    expect(resize_focus).to include("outline: 2px solid currentColor;")
    expect(active_filter).to include("font-weight: 700;")
    expect(active_filter).to include("text-decoration: underline;")
    expect(sorted_header).to include("font-weight: 700;")
  end

  it "keeps pinned and fixed column backgrounds overrideable with a system fallback" do
    expect(css).to include("[data-rails-table-preferences-pinned=\"true\"]")
    expect(css).to include("[data-rails-table-preferences-fixed=\"true\"]")
    expect(css).to include("background: var(--rails-table-preferences-pinned-background, canvas);")
  end
end
