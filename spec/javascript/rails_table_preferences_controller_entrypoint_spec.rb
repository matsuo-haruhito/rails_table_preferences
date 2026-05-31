# frozen_string_literal: true

RSpec.describe "rails_table_preferences/controller.js" do
  let(:source_path) do
    File.expand_path("../../app/javascript/rails_table_preferences/controller.js", __dir__)
  end

  let(:source) { File.read(source_path) }

  it "keeps the package entrypoint on the bundled controller subclass" do
    expect(source).to include('import RailsTablePreferencesBaseController from "../controllers/rails_table_preferences_controller"')
    expect(source).to include("export default class RailsTablePreferencesController extends RailsTablePreferencesBaseController")
  end

  it "labels the lightweight filter panel from its generated title" do
    expect(source).to include('this.filterPanel.setAttribute("role", "group")')
    expect(source).to include('this.filterPanel.setAttribute("aria-labelledby", this.filterPanelTitleId(column.key))')
    expect(source).to include('id="${this.filterPanelTitleId(column.key)}" class="rails-table-preferences-filter-panel__title"')
    expect(source).to include("return `${this.filterPanelId(key)}-title`")
  end

  it "does not turn the filter panel into a modal dialog" do
    expect(source).not_to include('role", "dialog"')
    expect(source).not_to include("aria-modal")
    expect(source).not_to include("focusTrap")
  end
end
