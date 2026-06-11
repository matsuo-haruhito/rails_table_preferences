# frozen_string_literal: true

RSpec.describe "RailsTablePreferences::Preferences not-found boundary", type: :request do
  let(:user) { User.create!(name: "User 1") }

  before do
    Thread.current[:rails_table_preferences_current_user] = user
  end

  it "keeps missing default loads on the existing fallback payload" do
    get "/rails_table_preferences/preferences/orders/default"

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to include(
      "table_key" => "orders",
      "name" => "default",
      "default" => false,
      "scope_type" => "owner",
      "editable" => true,
      "settings" => {
        "columns" => [],
        "filters" => {},
        "sorts" => []
      }
    )
  end

  it "returns not found for a missing non-default named preset" do
    get "/rails_table_preferences/preferences/orders/compact"

    expect(response).to have_http_status(:not_found)
    expect(JSON.parse(response.body)).to eq(
      "error" => "not_found",
      "message" => "Preference not found"
    )
  end

  it "returns not found for a missing explicitly scoped default preset" do
    get "/rails_table_preferences/preferences/orders/default", params: {
      scope_type: "role",
      scope_key: "ops"
    }

    expect(response).to have_http_status(:not_found)
    expect(JSON.parse(response.body)).to eq(
      "error" => "not_found",
      "message" => "Preference not found"
    )
  end

  it "still loads an existing explicitly scoped preset" do
    RailsTablePreferences::Preference.create!(
      scope_type: "role",
      scope_key: "ops",
      table_key: "orders",
      name: "default",
      settings: { "columns" => [{ "key" => "role_column" }] }
    )

    get "/rails_table_preferences/preferences/orders/default", params: {
      scope_type: "role",
      scope_key: "ops"
    }

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["scope_type"]).to eq("role")
    expect(json["scope_key"]).to eq("ops")
    expect(json["settings"]["columns"].first["key"]).to eq("role_column")
  end
end
