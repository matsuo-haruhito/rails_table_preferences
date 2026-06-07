# frozen_string_literal: true

require "spec_helper"
require "rexml/document"

RSpec.describe "visual overview documentation assets" do
  let(:docs_dir) { Pathname.new(__dir__).join("../../docs").expand_path }
  let(:overview_markdown) { docs_dir.join("visual_overview.md").read }
  let(:expected_svg_paths) do
    [
      "images/visual-overview-editor-and-table.svg",
      "images/visual-overview-filter-and-pinned-columns.svg"
    ]
  end

  it "links each overview image with descriptive markdown alt text" do
    expected_svg_paths.each do |svg_path|
      match = overview_markdown.match(/!\[(?<alt>[^\]]+)\]\(#{Regexp.escape(svg_path)}\)/)

      expect(match).not_to be_nil
      expect(match[:alt].strip).not_to be_empty
    end
  end

  it "keeps each SVG parseable and accessible as documentation evidence" do
    expected_svg_paths.each do |svg_path|
      svg_file = docs_dir.join(svg_path)

      expect(svg_file.exist?).to be(true)

      document = REXML::Document.new(svg_file.read)
      svg = document.root
      title = svg.elements["title"]
      desc = svg.elements["desc"]

      expect(svg.name).to eq("svg")
      expect(svg.attributes["width"]).to match(/\A\d+\z/)
      expect(svg.attributes["height"]).to match(/\A\d+\z/)
      expect(svg.attributes["viewBox"]).to match(/\A\d+ \d+ \d+ \d+\z/)
      expect(svg.attributes["role"]).to eq("img")
      expect(svg.attributes["aria-labelledby"].to_s.split).to include("title", "desc")
      expect(title&.attributes&.[]("id")).to eq("title")
      expect(title&.text.to_s.strip).not_to be_empty
      expect(desc&.attributes&.[]("id")).to eq("desc")
      expect(desc&.text.to_s.strip).not_to be_empty
    end
  end
end
