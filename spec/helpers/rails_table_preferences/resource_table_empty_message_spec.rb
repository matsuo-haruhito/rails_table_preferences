# frozen_string_literal: true

RSpec.describe "resource table empty message", type: :helper do
  it "renders a table-specific empty message for empty records" do
    html = helper.resource_table_for(
      User.none,
      only: [:name],
      render_editor: false,
      empty_message: "No users match this search"
    )

    expect(html).to include("No users match this search")
    expect(html).not_to include("No records to display")
    expect(html).not_to include("empty-message")
  end

  it "keeps the existing I18n fallback when no empty message is provided" do
    html = helper.resource_table_for(User.none, only: [:name], render_editor: false)

    expect(html).to include("No records to display")
  end

  it "does not render the empty message when records are present" do
    user = User.create!(name: "Alice")

    html = helper.resource_table_for(
      User.where(id: user.id),
      only: [:name],
      render_editor: false,
      empty_message: "No users match this search"
    )

    expect(html).to include("Alice")
    expect(html).not_to include("No users match this search")
  end

  it "escapes the empty message as plain text" do
    html = helper.resource_table_for(
      User.none,
      only: [:name],
      render_editor: false,
      empty_message: "<strong>No users</strong>"
    )

    expect(html).to include("&lt;strong&gt;No users&lt;/strong&gt;")
    expect(html).not_to include("<strong>No users</strong>")
  end
end
