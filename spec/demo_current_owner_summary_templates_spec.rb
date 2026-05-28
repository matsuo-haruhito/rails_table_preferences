# frozen_string_literal: true

require "spec_helper"

RSpec.describe "demo current owner summary templates" do
  let(:demo_view_template_path) do
    File.expand_path(
      "../lib/generators/rails_table_preferences/install/templates/demo/index.html.erb",
      __dir__
    )
  end

  let(:demo_controller_template_path) do
    File.expand_path(
      "../lib/generators/rails_table_preferences/install/templates/demo/orders_controller.rb",
      __dir__
    )
  end

  it "includes a current owner summary surface in the generated demo view" do
    template = File.read(demo_view_template_path)

    expect(template).to include("Current owner")
    expect(template).to include("@demo_owner_summary.fetch(\"model_name\")")
    expect(template).to include("@demo_owner_summary.fetch(\"display_name\")")
    expect(template).to include("@demo_owner_summary.fetch(\"identifier\")")
  end

  it "derives current owner summary data in the generated demo controller" do
    template = File.read(demo_controller_template_path)

    expect(template).to include("@demo_owner_summary = demo_owner_summary")
    expect(template).to include("def demo_owner_summary")
    expect(template).to include("RailsTablePreferences.configuration.current_user_method")
  end
end
