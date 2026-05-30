# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  describe "#tree_resource_table_for" do
    it "raises an actionable dependency error when tree_view is unavailable" do
      hide_const("TreeView") if Object.const_defined?(:TreeView)

      expect do
        helper.tree_resource_table_for(User.all, model: User)
      end.to raise_error(RuntimeError) { |error|
        expect(error.message).to include("tree_resource_table_for requires the tree_view gem")
        expect(error.message).to include("Add tree_view to the host app Gemfile")
        expect(error.message).to include("resource_table_for/custom tree_resource_table_partial")
        expect(error.message).to include("docs/resource_tables.md#treeview-integration")
      }
    end
  end
end
