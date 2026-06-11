# frozen_string_literal: true

require "spec_helper"
require "rexml/document"

RSpec.describe "visual overview documentation assets" do
  let(:docs_dir) { Pathname.new(__dir__).join("../../docs").expand_path }
  let(:repo_root) { docs_dir.parent }
  let(:overview_markdown) { docs_dir.join("visual_overview.md").read }
  let(:readme_markdown) { repo_root.join("README.md").read }
  let(:expected_svg_paths) do
    [
      "images/visual-overview-editor-and-table.svg",
      "images/visual-overview-filter-and-pinned-columns.svg"
    ]
  end
  let(:copy_consistency_signals) do
    {
      "images/visual-overview-editor-and-table.svg" => {
        overview: [/shared preset/i, /scoped preset/i, /orders screen/i],
        readme: [/preset editor/i, /scoped preset/i, /orders table/i],
        svg: [/editor/i, /scoped preset/i, /export preview/i]
      },
      "images/visual-overview-filter-and-pinned-columns.svg" => {
        overview: [/grouped/i, /fixed-column/i, /demo-aligned/i],
        svg: [/grouped header/i, /fixed column/i, /generated demo/i]
      }
    }
  end

  def markdown_alt_for(markdown, path)
    match = markdown.match(/!\[(?<alt>[^\]]+)\]\(#{Regexp.escape(path)}\)/)

    match&.[](:alt)&.strip
  end

  def svg_accessibility_text_for(svg_file)
    document = REXML::Document.new(svg_file.read)
    svg = document.root

    [
      svg.elements["title"]&.text.to_s.strip,
      svg.elements["desc"]&.text.to_s.strip
    ].join(" ")
  end

  it "links each overview image with descriptive markdown alt text" do
    expected_svg_paths.each do |svg_path|
      alt_text = markdown_alt_for(overview_markdown, svg_path)

      expect(alt_text).not_to be_nil
      expect(alt_text).not_to be_empty
    end
  end

  it "keeps README, overview alt text, and SVG title/desc aligned on the first-visual promise" do
    copy_consistency_signals.each do |svg_path, signals|
      overview_alt = markdown_alt_for(overview_markdown, svg_path)
      svg_text = svg_accessibility_text_for(docs_dir.join(svg_path))

      signals.fetch(:overview).each do |pattern|
        expect(overview_alt).to match(pattern)
      end

      signals.fetch(:svg).each do |pattern|
        expect(svg_text).to match(pattern)
      end

      next unless signals[:readme]

      readme_alt = markdown_alt_for(readme_markdown, "docs/#{svg_path}")

      signals.fetch(:readme).each do |pattern|
        expect(readme_alt).to match(pattern)
      end
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
