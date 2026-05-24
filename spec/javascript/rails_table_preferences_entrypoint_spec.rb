# frozen_string_literal: true

RSpec.describe "rails_table_preferences JavaScript entrypoints" do
  let(:controller_entrypoint_path) do
    File.expand_path("../../app/javascript/rails_table_preferences/controller.js", __dir__)
  end

  let(:index_entrypoint_path) do
    File.expand_path("../../app/javascript/rails_table_preferences/index.js", __dir__)
  end

  it "exports the bundled Stimulus controller from a stable controller path" do
    source = File.read(controller_entrypoint_path)

    expect(source).to include('import RailsTablePreferencesController from "../controllers/rails_table_preferences_controller"')
    expect(source).to include("export default RailsTablePreferencesController")
  end

  it "exports the controller from the package root as both default and named export" do
    source = File.read(index_entrypoint_path)

    expect(source).to include('export { default } from "./controller"')
    expect(source).to include('export { default as RailsTablePreferencesController } from "./controller"')
  end
end
