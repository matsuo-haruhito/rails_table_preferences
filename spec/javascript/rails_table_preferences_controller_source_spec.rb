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

  it "defaults filter UI labels to Japanese" do
    expect(source).to include('filterLabel: { type: String, default: "絞り込み" }')
    expect(source).to include('filterApplyLabel: { type: String, default: "適用" }')
    expect(source).to include('filterClearLabel: { type: String, default: "クリア" }')
    expect(source).to include('filterOperatorLabel: { type: String, default: "条件" }')
    expect(source).to include('filterValueLabel: { type: String, default: "値" }')
    expect(source).to include('filterFromLabel: { type: String, default: "開始" }')
    expect(source).to include('filterToLabel: { type: String, default: "終了" }')
  end

  it "defaults sort UI labels to Japanese" do
    expect(source).to include('sortAscLabel: { type: String, default: "昇順" }')
    expect(source).to include('sortDescLabel: { type: String, default: "降順" }')
    expect(source).to include('sortClearLabel: { type: String, default: "並び替え解除" }')
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

  it "does not start table dragging from header controls" do
    expect(source).to include("shouldIgnoreHeaderAction(target)")
    expect(source).to include('target.closest("[data-rails-table-preferences-filter-button]")')
    expect(source).to include('target.closest("[data-rails-table-preferences-resize-handle]")')
  end

  it "supports column resize with a widened hit area" do
    expect(source).to include("resizeHandleWidth: { type: Number, default: 10 }")
    expect(source).to include("applyResizeHandleHitArea(cell, handle)")
    expect(source).to include("handle.style.width = `${this.normalizedResizeHandleWidth}px`")
    expect(source).to include("startColumnResize(event)")
    expect(source).to include("resizeColumn(event)")
  end

  it "installs filter buttons for filterable columns" do
    expect(source).to include("installFilterControls()")
    expect(source).to include("column?.filter")
    expect(source).to include('button.dataset.railsTablePreferencesFilterButton = "true"')
    expect(source).to include("toggleFilterPanel(event, cell, column)")
  end

  it "builds filter panels and stores neutral filter conditions" do
    expect(source).to include("filterPanelHtml(column)")
    expect(source).to include("filterValueHtml(filter, condition, selectedOperator)")
    expect(source).to include("applyFilterPanel(key, panel)")
    expect(source).to include("updateFilterCondition(key, condition)")
    expect(source).to include("filters: this.settingsValue?.filters || {}")
  end

  it "supports common filter types and operators" do
    expect(source).to include('case "number"')
    expect(source).to include('case "date"')
    expect(source).to include('case "select"')
    expect(source).to include('case "boolean"')
    expect(source).to include('return ["contains", "equals", "starts_with", "ends_with", "blank", "present"]')
  end

  it "supports sortable header click UI" do
    expect(source).to include("installSortControls()")
    expect(source).to include("toggleSortFromHeader(event, cell, column)")
    expect(source).to include("syncSortStates()")
    expect(source).to include("sortFor(key)")
    expect(source).to include('indicator.textContent = sort?.direction === "asc" ? "▲"')
    expect(source).to include('cell.setAttribute("aria-sort"')
  end
end
