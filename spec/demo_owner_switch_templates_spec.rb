# frozen_string_literal: true

require "spec_helper"

RSpec.describe "demo owner switch templates" do
  let(:controller_template_path) do
    File.expand_path("../lib/generators/rails_table_preferences/install/templates/demo/orders_controller.rb", __dir__)
  end

  let(:view_template_path) do
    File.expand_path("../lib/generators/rails_table_preferences/install/templates/demo/index.html.erb", __dir__)
  end

  it "provides demo-local owner switch wiring in the generated controller" do
    template = File.read(controller_template_path)

    expect(template).to include('DEMO_OWNER_PARAM = "demo_owner"')
    expect(template).to include('DEMO_OWNER_SWITCH_LABELS = ["Demo owner A", "Demo owner B"].freeze')
    expect(template).to include('define_method(owner_method_name) do')
    expect(template).to include('demo_owner_override')
    expect(template).to include('demo_available_owner_records.each_with_index')
    expect(template).to include('request.query_parameters.except(DEMO_OWNER_PARAM)')
  end

  it "renders the generated owner switch surface in the demo view" do
    template = File.read(view_template_path)

    expect(template).to include("<h3>Owner switch</h3>")
    expect(template).to include('switch.fetch("label")')
    expect(template).to include('switch.fetch("description")')
    expect(template).to include('rails-table-preferences-demo-owner-switch')
    expect(template).to include('@demo_owner_switch_ready')
  end
end
