# frozen_string_literal: true

RSpec.describe "rails_table_preferences_controller.js" do
  let(:source_path) do
    File.expand_path("../../app/javascript/controllers/rails_table_preferences_controller.js", __dir__)
  end

  let(:source) { File.read(source_path) }

  it "defaults generated editor labels to Japanese" do
    expect(source).to include('orderLabel: { type: String, default: "表示順" }')
    expect(source).to include('widthLabel: { type: String, default: "列幅" }')
    expect(source).to include('truncateLabel: { type: String, default: "省略文字数" }')
    expect(source).to include('dragLabel: { type: String, default: "ドラッグして並び替え" }')
    expect(source).to include('resizeLabel: { type: String, default: "列幅を変更" }')
  end

  it "builds editor rows with localized Stimulus values" do
    expect(source).to include('${this.escapeHtml(this.orderLabelValue)}')
    expect(source).to include('${this.escapeHtml(this.widthLabelValue)}')
    expect(source).to include('${this.escapeHtml(this.truncateLabelValue)}')
    expect(source).to include('${this.escapeHtml(this.dragLabelValue)}')
  end

  it "restricts column display effects to the table element" do
    expect(source).to include("cellsFor(key)")
    expect(source).to include("const table = this.tableElement")
    expect(source).to include('return table.querySelectorAll(`[data-rails-table-preferences-column-key="${CSS.escape(key)}"]`)')
    expect(source).not_to include('return this.element.querySelectorAll(`[data-rails-table-preferences-column-key="${CSS.escape(key)}"]`)')
  end

  it "keeps a dedicated tableElement getter used by table operations" do
    expect(source).to include("get tableElement()")
    expect(source).to include('this.element.tagName === "TABLE" ? this.element : this.element.querySelector("table")')
    expect(source).to include("get headerCells()")
    expect(source).to include("get tableRows()")
  end

  it "supports direct table header reordering" do
    expect(source).to include("installTableColumnDragHandles()")
    expect(source).to include("startTableColumnDrag(event)")
    expect(source).to include("dragTableColumnOver(event)")
    expect(source).to include("moveColumnInSettings(draggedKey, targetKey, placement)")
    expect(source).to include("reorderSensitivity")
  end

  it "supports column resize with a widened hit area" do
    expect(source).to include("resizeHandleWidth: { type: Number, default: 10 }")
    expect(source).to include("applyResizeHandleHitArea(cell, handle)")
    expect(source).to include("handle.style.width = `${this.normalizedResizeHandleWidth}px`")
    expect(source).to include("startColumnResize(event)")
    expect(source).to include("resizeColumn(event)")
  end
end
