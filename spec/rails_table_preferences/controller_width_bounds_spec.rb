# frozen_string_literal: true

require "spec_helper"

RSpec.describe "packaged Rails Table Preferences controller width bounds" do
  let(:source) { File.read(repository_root.join("app/javascript/rails_table_preferences/controller.js")) }

  it "keeps column width boundary metadata in default and merged settings" do
    expect(source).to include("buildDefaultSettings()")
    expect(source).to include("mergeSettings(defaultSettings, savedSettings)")
    expect(source).to include("withColumnWidthMetadata(column)")
    expect(source).to include("min_width")
    expect(source).to include("max_width")
  end

  it "clamps editor, drag resize, auto-fit, applied, and pinned offset widths through one helper" do
    expect(source).to include("width: this.clampColumnWidth(key")
    expect(source).to include("this.clampColumnWidth(this.resizingColumn.key, measuredWidth, { min: 40 })")
    expect(source).to include("this.clampColumnWidth(key, Math.ceil(measured)")
    expect(source).to include("super.applyColumn(this.columnWithClampedWidth(column))")
    expect(source).to include("left += this.clampColumnWidth(column.key, column.width)")
  end

  def repository_root
    Pathname.new(File.expand_path("../..", __dir__))
  end
end
