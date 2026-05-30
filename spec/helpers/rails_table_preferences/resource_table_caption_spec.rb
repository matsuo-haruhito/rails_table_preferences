# frozen_string_literal: true

RSpec.describe "resource table captions", type: :helper do
  let(:columns) { [{ "key" => "customer_name", "label" => "Customer" }] }
  let(:table_state) { { "visible_columns" => columns } }
  let(:model_name) { double("model_name", route_key: "orders") }
  let(:model) { double("Order", model_name: model_name) }
  let(:records) { double("records", klass: model) }

  before do
    allow(helper).to receive(:table_preferences_resource_columns).and_return(columns)
    allow(helper).to receive(:table_preferences_state).and_return(table_state)
  end

  it "passes resource table captions as partial locals without mixing them into table options" do
    expect(helper).to receive(:render).with(
      partial: RailsTablePreferences.configuration.resource_table_partial,
      locals: hash_including(
        caption: "Orders",
        options: satisfy { |options| options[:id] == "orders-table" && !options.key?(:caption) }
      )
    ).and_return("resource table")

    expect(helper.resource_table_for(records, caption: "Orders", id: "orders-table")).to eq("resource table")
  end

  it "keeps caption absent by default" do
    expect(helper).to receive(:render).with(
      partial: RailsTablePreferences.configuration.resource_table_partial,
      locals: hash_including(caption: nil)
    ).and_return("resource table")

    expect(helper.resource_table_for(records)).to eq("resource table")
  end

  it "passes tree resource table captions using the same local contract" do
    expect(helper).to receive(:render).with(
      partial: RailsTablePreferences.configuration.tree_resource_table_partial,
      locals: hash_including(
        caption: "Projects",
        options: satisfy { |options| options[:class] == "project-tree" && !options.key?(:caption) }
      )
    ).and_return("tree resource table")

    expect(helper.tree_resource_table_for(records, caption: "Projects", class: "project-tree")).to eq("tree resource table")
  end

  it "renders an escaped caption in the default resource table partial" do
    html = helper.render(
      partial: "rails_table_preferences/resource_table",
      locals: {
        records: [],
        model: model,
        table_key: "orders",
        name: "default",
        settings: {},
        columns: columns,
        table_state: table_state,
        profile: nil,
        caption: "Orders <internal>",
        options: {}
      }
    )

    expect(html).to include("<caption>Orders &lt;internal&gt;</caption>")
    expect(html).not_to include("caption=\"")
  end

  it "does not render a caption element when caption is blank" do
    html = helper.render(
      partial: "rails_table_preferences/resource_table",
      locals: {
        records: [],
        model: model,
        table_key: "orders",
        name: "default",
        settings: {},
        columns: columns,
        table_state: table_state,
        profile: nil,
        caption: nil,
        options: {}
      }
    )

    expect(html).not_to include("<caption")
  end
end
