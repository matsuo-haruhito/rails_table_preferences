# frozen_string_literal: true

RSpec.describe "resource table model inference", type: :helper do
  let(:columns) { [{ "key" => "name", "label" => "Name" }] }
  let(:table_state) { { "visible_columns" => columns } }
  let(:model_name) { double("model_name", route_key: "orders") }
  let(:model) { double("Order", model_name: model_name) }

  before do
    allow(helper).to receive(:table_preferences_resource_columns).and_return(columns)
    allow(helper).to receive(:table_preferences_state).and_return(table_state)
  end

  it "keeps empty relation-like collections inferable through klass" do
    model_value = model
    records = Object.new
    records.define_singleton_method(:klass) { model_value }

    expect(helper).to receive(:render).with(
      partial: RailsTablePreferences.configuration.resource_table_partial,
      locals: hash_including(records: records, model: model, table_key: "orders")
    ).and_return("resource table")

    expect(helper.resource_table_for(records)).to eq("resource table")
  end

  it "keeps profile model inference available for empty plain arrays" do
    model_value = model
    profile = Object.new
    profile.define_singleton_method(:model) { model_value }

    expect(helper).to receive(:render).with(
      partial: RailsTablePreferences.configuration.resource_table_partial,
      locals: hash_including(records: [], model: model, profile: profile, table_key: "orders")
    ).and_return("resource table")

    expect(helper.resource_table_for([], profile: profile)).to eq("resource table")
  end

  it "keeps first record class fallback for plain arrays with rows" do
    model_name_value = model_name
    inferred_model = Class.new do
      define_singleton_method(:model_name) { model_name_value }
    end
    records = [inferred_model.new]

    expect(helper).to receive(:render).with(
      partial: RailsTablePreferences.configuration.resource_table_partial,
      locals: hash_including(records: records, model: inferred_model, table_key: "orders")
    ).and_return("resource table")

    expect(helper.resource_table_for(records)).to eq("resource table")
  end

  it "raises an actionable error for empty plain arrays without a model" do
    expect do
      helper.resource_table_for([])
    end.to raise_error(ArgumentError) { |error|
      expect(error.message).to include("model: is required")
      expect(error.message).to include("empty plain Array")
      expect(error.message).to include("Pass model:")
      expect(error.message).to include("ActiveRecord::Relation")
      expect(error.message).to include("records.klass")
    }
  end

  it "uses the same model requirement for tree resource tables" do
    expect do
      helper.tree_resource_table_for([])
    end.to raise_error(ArgumentError) { |error|
      expect(error.message).to include("empty plain Array")
      expect(error.message).to include("Pass model:")
      expect(error.message).to include("records.klass")
    }
  end
end
