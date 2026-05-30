# frozen_string_literal: true

RSpec.describe "resource table rendering", type: :helper do
  before do
    RailsTablePreferences.configuration.unresolved_label_behavior = :humanize
  end

  it "renders an empty row with a visible-column colspan" do
    html = helper.resource_table_for(User.none, model: User, table_key: :users, only: %i[name created_at])

    expect(html).to include('class="rails-table-preferences-resource-table__empty-cell" colspan="2"')
    expect(html).to include("No records to display")
  end

  it "uses the localized empty copy" do
    I18n.with_locale(:ja) do
      html = helper.resource_table_for(User.none, model: User, table_key: :users, only: %i[name])

      expect(html).to include('class="rails-table-preferences-resource-table__empty-cell" colspan="1"')
      expect(html).to include("表示できるレコードがありません")
    end
  end

  it "keeps non-empty resource tables unchanged" do
    user = User.create!(name: "Alice")

    html = helper.resource_table_for(User.where(id: user.id), model: User, table_key: :users, only: %i[name])

    expect(html).to include("Alice")
    expect(html).not_to include("rails-table-preferences-resource-table__empty-row")
  end
end
