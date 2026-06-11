# frozen_string_literal: true

require "spec_helper"

RSpec.describe "demo scope context switch templates" do
  let(:controller_template_path) do
    File.expand_path("../lib/generators/rails_table_preferences/install/templates/demo/orders_controller.rb", __dir__)
  end

  let(:view_template_path) do
    File.expand_path("../lib/generators/rails_table_preferences/install/templates/demo/index.html.erb", __dir__)
  end

  it "provides demo-local scope context switch modes" do
    template = File.read(controller_template_path)

    expect(template).to include('DEMO_SCOPE_CONTEXT_PARAM = "demo_scope_context"')
    expect(template).to include('"label" => "Host app context"')
    expect(template).to include('"label" => "Owner-only baseline"')
    expect(template).to include('"label" => "Role preset lane"')
    expect(template).to include('"label" => "Organization preset lane"')
    expect(template).to include('return super if defined?(super)')
    expect(template).to include('request.query_parameters.except(DEMO_SCOPE_CONTEXT_PARAM)')
  end

  it "renders the generated demo scope switch surface" do
    template = File.read(view_template_path)

    expect(template).to include("<h3>Scope switch</h3>")
    expect(template).to include('switch.fetch("label")')
    expect(template).to include('rails-table-preferences-demo-scope-switch')
    expect(template).to include('table_preference_scope_context')
  end
end
