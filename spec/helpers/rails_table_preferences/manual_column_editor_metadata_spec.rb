# frozen_string_literal: true

require "spec_helper"

RSpec.describe "manual column editor metadata" do
  class ManualColumnEditorMetadataAdapter
    def to_table_cell_editor
      {
        type: :rails_fields_kit,
        method: :status,
        options: { helper: :enum_select }
      }
    end
  end

  let(:helper) do
    Class.new do
      include RailsTablePreferences::TablePreferencesHelper

      def view_context
        self
      end
    end.new
  end

  it "keeps symbol editor metadata on manual column definitions" do
    column = helper.table_preferences_column(:status, label: "Status", editor: :select)

    expect(column).to include(
      "key" => "status",
      "label" => "Status",
      "editor" => { "type" => "select" }
    )
  end

  it "normalizes hash editor metadata without changing existing filter metadata" do
    column = helper.table_preferences_column(
      :status,
      label: "Status",
      filter: { type: :select, options: [{ value: :draft, label: :Draft }] },
      editor: { type: :rails_fields_kit, method: :status, options: { helper: :enum_select } },
      sortable: true,
      sort_param: :status_sort
    )

    expect(column["editor"]).to eq(
      "type" => "rails_fields_kit",
      "method" => "status",
      "options" => { "helper" => :enum_select }
    )
    expect(column["filter"]).to eq(
      "type" => "select",
      "options" => [{ "value" => "draft", "label" => "Draft" }]
    )
    expect(column["sortable"]).to be(true)
    expect(column["sort_param"]).to eq("status_sort")
  end

  it "supports table cell editor metadata objects" do
    column = helper.table_preferences_column(:status, label: "Status", editor: ManualColumnEditorMetadataAdapter.new)

    expect(column["editor"]).to eq(
      "type" => "rails_fields_kit",
      "method" => "status",
      "options" => { "helper" => :enum_select }
    )
  end

  it "omits blank or disabled editor metadata" do
    expect(helper.table_preferences_column(:name, label: "Name", editor: nil)).not_to have_key("editor")
    expect(helper.table_preferences_column(:name, label: "Name", editor: false)).not_to have_key("editor")
  end

  it "passes manual editor metadata to the registered editor renderer" do
    renderer = instance_double("RailsTablePreferences::RendererRegistry")
    allow(renderer).to receive(:call).and_return("rendered editor")
    allow(RailsTablePreferences.configuration).to receive(:editor_renderers).and_return(renderer)

    form = double("form")
    record = double("record")
    column = helper.table_preferences_column(
      :status,
      label: "Status",
      editor: { type: :rails_fields_kit, method: :status, options: { helper: :enum_select } }
    )

    expect(helper.table_preferences_cell_editor(form: form, record: record, column: column)).to eq("rendered editor")
    expect(renderer).to have_received(:call).with(
      "rails_fields_kit",
      form: form,
      record: record,
      method: "status",
      editor: column.fetch("editor"),
      column: column,
      view_context: helper
    )
  end
end
