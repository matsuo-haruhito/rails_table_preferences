# frozen_string_literal: true

RSpec.describe "Scoped preset resolution", type: :request do
  let(:user) { User.create!(name: "User 1") }

  before do
    Thread.current[:rails_table_preferences_current_user] = user
    Thread.current[:rails_table_preferences_scope_context] = { roles: ["admin"], organization: "tokyo" }
  end

  it "loads the explicitly selected scope when same-name presets exist" do
    RailsTablePreferences::Preference.create!(
      user: user,
      table_key: "orders",
      name: "default",
      settings: { "columns" => [{ "key" => "owner_column" }] }
    )
    RailsTablePreferences::Preference.create!(
      scope_type: "role",
      scope_key: "admin",
      table_key: "orders",
      name: "default",
      settings: { "columns" => [{ "key" => "role_column" }] }
    )
    RailsTablePreferences::Preference.create!(
      scope_type: "organization",
      scope_key: "tokyo",
      table_key: "orders",
      name: "default",
      settings: { "columns" => [{ "key" => "organization_column" }] }
    )

    get "/rails_table_preferences/preferences/orders/default", params: {
      scope_type: "role",
      scope_key: "admin"
    }

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["scope_type"]).to eq("role")
    expect(json["scope_key"]).to eq("admin")
    expect(json["editable"]).to eq(false)
    expect(json["settings"]["columns"].first["key"]).to eq("role_column")
  end

  it "keeps name-only requests on the existing priority resolver" do
    RailsTablePreferences::Preference.create!(
      user: user,
      table_key: "orders",
      name: "default",
      settings: { "columns" => [{ "key" => "owner_column" }] }
    )
    RailsTablePreferences::Preference.create!(
      scope_type: "role",
      scope_key: "admin",
      table_key: "orders",
      name: "default",
      settings: { "columns" => [{ "key" => "role_column" }] }
    )

    get "/rails_table_preferences/preferences/orders/default"

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["scope_type"]).to eq("owner")
    expect(json["settings"]["columns"].first["key"]).to eq("owner_column")
  end
end
