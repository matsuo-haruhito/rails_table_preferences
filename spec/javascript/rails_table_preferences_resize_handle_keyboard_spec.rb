# frozen_string_literal: true

RSpec.describe "rails table preferences resize handle keyboard contract" do
  let(:entrypoint_source) { File.read("app/javascript/rails_table_preferences/controller.js") }

  it "keeps Enter and Space wired to resize handle auto-fit in the package entrypoint" do
    expect(entrypoint_source).to include("autoFitColumnFromResizeHandleKeyboard")
    expect(entrypoint_source).to include("autoFitColumnFromHandle(event)")
    expect(entrypoint_source).to include('event.key === "Enter"')
    expect(entrypoint_source).to include('event.key === " "')
  end

  it "does not introduce arrow-key step resizing in the bundled keyboard contract" do
    expect(entrypoint_source).not_to include('event.key === "ArrowLeft"')
    expect(entrypoint_source).not_to include('event.key === "ArrowRight"')
  end
end
