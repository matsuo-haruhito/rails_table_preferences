# frozen_string_literal: true

RSpec.describe RailsTablePreferences::RendererRegistry do
  subject(:registry) { described_class.new }

  it "registers and calls a block renderer with the context hash" do
    registry.register(:badge) { |context| "#{context.fetch(:label)}:#{context.fetch(:value)}" }

    expect(registry.fetch(:badge)).to respond_to(:call)
    expect(registry).to be_registered(:badge)
    expect(registry.keys).to eq(["badge"])
    expect(registry.call(:badge, value: 7, label: "Priority")).to eq("Priority:7")
  end

  it "calls an arity-one callable with the full context hash" do
    renderer = lambda { |context| context.fetch(:record).fetch(:name).upcase }

    registry.register("name", renderer)

    expect(registry.call(:name, record: {name: "alice"})).to eq("ALICE")
  end

  it "calls callable objects that accept keyword context" do
    renderer = Class.new do
      def call(value:, suffix:)
        "#{value}#{suffix}"
      end
    end.new

    registry.register(:status, renderer)

    expect(registry.call("status", value: "active", suffix: "!")).to eq("active!")
  end

  it "returns nil for unregistered renderers so helpers can use fallbacks" do
    expect(registry.fetch(:missing)).to be_nil
    expect(registry).not_to be_registered(:missing)
    expect(registry.call(:missing, value: "fallback")).to be_nil
  end

  it "exposes registered? and keys as lightweight missing-renderer diagnostics" do
    registry.register(:badge) { |context| context.fetch(:label) }
    registry.register("status") { |context| context.fetch(:value) }

    expect(registry.keys).to eq(%w[badge status])
    expect(registry).to be_registered(:badge)
    expect(registry).to be_registered("status")
    expect(registry).not_to be_registered(:missing)
    expect(registry.call(:missing, value: "fallback")).to be_nil
  end

  it "rejects non-callable renderers" do
    expect { registry.register(:broken, "not callable") }
      .to raise_error(ArgumentError, "renderer must respond to call")
  end
end
