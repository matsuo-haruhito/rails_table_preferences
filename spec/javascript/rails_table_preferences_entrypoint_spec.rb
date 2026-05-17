# frozen_string_literal: true

RSpec.describe "rails_table_preferences JavaScript entrypoints" do
  let(:controller_entrypoint_path) do
    File.expand_path("../../app/javascript/rails_table_preferences/controller.js", __dir__)
  end

  let(:index_entrypoint_path) do
    File.expand_path("../../app/javascript/rails_table_preferences/index.js", __dir__)
  end

  let(:package_json_path) do
    File.expand_path("../../package.json", __dir__)
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

  it "declares package exports for JavaScript bundlers such as Vite" do
    package_json = File.read(package_json_path)

    expect(package_json).to include('"name": "rails_table_preferences"')
    expect(package_json).to include('".": "./app/javascript/rails_table_preferences/index.js"')
    expect(package_json).to include('"./controller": "./app/javascript/rails_table_preferences/controller.js"')
  end
end
