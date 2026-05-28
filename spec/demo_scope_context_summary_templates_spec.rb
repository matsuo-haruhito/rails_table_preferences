# frozen_string_literal: true

require "spec_helper"

RSpec.describe "demo scope context summary templates" do
  let(:controller_template_path) do
    File.expand_path("../lib/generators/rails_table_preferences/install/templates/demo/orders_controller.rb", __dir__)
  end

  let(:view_template_path) do
    File.expand_path("../lib/generators/rails_table_preferences/install/templates/demo/index.html.erb", __dir__)
  end

  it "builds a summary from the configured scope context method" do
    template = File.read(controller_template_path)

    expect(template).to include('@demo_scope_context_summary = demo_scope_context_summary')
    expect(template).to include('RailsTablePreferences.configuration.scope_context_method')
    expect(template).to include('"owner_only" => roles.empty? && organization.blank?')
    expect(template).to include('"roles" => roles')
    expect(template).to include('"organization" => organization')
  end

  it "shows the current scope context in the generated demo view" do
    template = File.read(view_template_path)

    expect(template).to include("<h2>Current scope context</h2>")
    expect(template).to include("owner-only")
    expect(template).to include('roles: [#{@demo_scope_context_summary.fetch("roles").join(", ")}]')
    expect(template).to include('organization: #{@demo_scope_context_summary["organization"]}')
  end
end
