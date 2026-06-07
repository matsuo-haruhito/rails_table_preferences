# frozen_string_literal: true

require "spec_helper"

RSpec.describe "package filter panel viewport positioning" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:package_controller_source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }
  let(:base_controller_source) { File.read(File.join(repo_root, "app/javascript/controllers/rails_table_preferences_controller.js")) }

  it "keeps the viewport clamp in the package entrypoint without changing copied controller positioning" do
    expect(package_controller_source).to include("positionFilterPanel(panel, headerCell)")
    expect(package_controller_source).to include("viewportMargin = 8")
    expect(package_controller_source).to include("window.innerWidth - panelWidth - viewportMargin")
    expect(package_controller_source).to include("Math.max(minLeft, Math.min(desiredLeft, maxLeft))")
    expect(package_controller_source).to include("panel.style.maxWidth = `calc(100vw - ${viewportMargin * 2}px)`")

    expect(base_controller_source).to include("panel.style.left = `${window.scrollX + rect.left}px`")
    expect(base_controller_source).not_to include("window.innerWidth - panelWidth - viewportMargin")
  end
end
