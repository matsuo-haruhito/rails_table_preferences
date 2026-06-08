# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rails_table_preferences package-only controller values" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:base_controller_source) { File.read(File.join(repo_root, "app/javascript/controllers/rails_table_preferences_controller.js")) }
  let(:package_controller_source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }

  let(:package_only_values) do
    %w[
      filterOperatorLabels
      editorSearchLabel
      editorSearchPlaceholder
      editorNoSearchResultsLabel
      moveUpLabel
      moveDownLabel
    ]
  end

  it "keeps editor affordance labels in the package entrypoint boundary" do
    package_only_values.each do |value_name|
      expect(package_controller_source).to include("#{value_name}:"), "expected package entrypoint to expose #{value_name}"
      expect(base_controller_source).not_to include("#{value_name}:"), "expected copied/base controller not to expose package-only #{value_name}"
    end
  end
end
