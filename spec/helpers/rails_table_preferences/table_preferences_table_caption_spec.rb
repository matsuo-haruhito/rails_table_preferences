# frozen_string_literal: true

RSpec.describe "manual table helper captions", type: :helper do
  it "renders an optional native caption before table content" do
    html = helper.table_preferences_table_tag(
      table_key: :orders,
      columns: [helper.table_preferences_column(:customer_name, label: "Customer Name")],
      caption: "Orders"
    ) do
      safe_join([
        tag.thead(tag.tr(tag.th("Customer Name"))),
        tag.tbody(tag.tr(tag.td("ACME")))
      ])
    end

    table = Nokogiri::HTML.fragment(html).at_css("table")

    expect(table.children.first.name).to eq("caption")
    expect(table.at_css("caption").text).to eq("Orders")
    expect(table.at_css("thead th").text).to eq("Customer Name")
    expect(table["data-rails-table-preferences-table-key-value"]).to eq("orders")
  end

  it "escapes caption text using normal Rails tag escaping" do
    html = helper.table_preferences_table_tag(
      table_key: :orders,
      columns: [helper.table_preferences_column(:customer_name, label: "Customer Name")],
      caption: "Orders <Today> & VIP"
    ) { tag.tbody(tag.tr(tag.td("ACME"))) }

    expect(html).to include("<caption>Orders &lt;Today&gt; &amp; VIP</caption>")
  end

  it "keeps existing block rendering unchanged when caption is not passed" do
    html = helper.table_preferences_table_tag(
      table_key: :orders,
      columns: [helper.table_preferences_column(:customer_name, label: "Customer Name")]
    ) { tag.tbody(tag.tr(tag.td("ACME"))) }

    table = Nokogiri::HTML.fragment(html).at_css("table")

    expect(table.at_css("caption")).to be_nil
    expect(table.at_css("tbody td").text).to eq("ACME")
  end

  it "documents the host-owned duplicate caption boundary" do
    docs = File.read(File.expand_path("../../../docs/manual_table_captions.md", __dir__))

    expect(docs).to include("table_preferences_table_tag")
    expect(docs).to include("caption:")
    expect(docs).to include("Do not also render a second `<caption>` inside the block")
  end
end
