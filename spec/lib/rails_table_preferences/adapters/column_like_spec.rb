# frozen_string_literal: true

RSpec.describe RailsTablePreferences::Adapters::ColumnLike do
  it "preserves overflow metadata from hash columns" do
    column = described_class.call(
      key: :description,
      label: "Description",
      overflow: :wrap
    )

    expect(column).to include(
      "key" => "description",
      "overflow" => "wrap"
    )
  end

  it "preserves default_overflow metadata from hash columns" do
    column = described_class.call(
      key: :description,
      label: "Description",
      default_overflow: :ellipsis
    )

    expect(column).to include(
      "key" => "description",
      "overflow" => "ellipsis"
    )
  end
end