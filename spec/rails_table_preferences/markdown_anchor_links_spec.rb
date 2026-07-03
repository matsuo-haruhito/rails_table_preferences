# frozen_string_literal: true

require "spec_helper"
require "rails_table_preferences/package_verifier"
require "pathname"
require "set"

RSpec.describe "Markdown anchor links" do
  it "keeps local anchors from required Markdown entrypoints resolvable" do
    unresolved = markdown_anchor_links.filter_map do |link|
      target_path = link.fetch(:target_path)
      next unless File.exist?(repository_root.join(target_path))

      anchors = heading_anchors_for(target_path)
      next if anchors.include?(link.fetch(:anchor))

      "#{link.fetch(:source)} links to #{link.fetch(:href)}, but #{target_path} does not define ##{link.fetch(:anchor)}"
    end

    expect(unresolved).to eq([])
  end

  def markdown_anchor_links
    markdown_entrypoint_paths.flat_map do |source|
      source_text = strip_fenced_code_blocks(File.read(repository_root.join(source)))

      source_text.scan(/!?(?<bang>!)?\[[^\]]*\]\((?<href>[^)\s]+)(?:\s+"[^"]*")?\)/).filter_map do |bang, href|
        next if bang

        href = href.delete_prefix("<").delete_suffix(">")
        target_path, fragment = href.split("#", 2)
        next if fragment.nil? || fragment.empty?
        next if external_href?(href)

        target_path = source if target_path.empty?
        target_path = Pathname.new(File.dirname(source)).join(target_path).cleanpath.to_s
        next unless target_path.end_with?(".md")

        {
          source: source,
          href: href,
          target_path: target_path,
          anchor: normalize_fragment(fragment)
        }
      end
    end
  end

  def markdown_entrypoint_paths
    @markdown_entrypoint_paths ||= (["README.md", "docs/index.md"] + RailsTablePreferences::PackageVerifier::REQUIRED_PATHS.grep(/\.md\z/))
      .uniq
      .select { |path| File.exist?(repository_root.join(path)) }
  end

  def heading_anchors_for(path)
    anchors = Set.new
    counts = Hash.new(0)

    strip_fenced_code_blocks(File.read(repository_root.join(path))).each_line do |line|
      heading = line.match(/\A\#{1,6}\s+(?<text>.+?)\s*#*\s*\z/)
      next unless heading

      base_anchor = heading_anchor(heading[:text])
      next if base_anchor.empty?

      count = counts[base_anchor]
      anchors << (count.zero? ? base_anchor : "#{base_anchor}-#{count}")
      counts[base_anchor] += 1
    end

    anchors
  end

  def strip_fenced_code_blocks(markdown)
    markdown.gsub(/```.*?```/m, "")
  end

  def external_href?(href)
    href.match?(%r{\A(?:[a-z][a-z0-9+.-]*:)?//}i) || href.match?(%r{\A(?:mailto|tel):}i)
  end

  def normalize_fragment(fragment)
    fragment.to_s.sub(/\A#/, "").downcase
  end

  def heading_anchor(text)
    text
      .gsub(/<[^>]+>/, "")
      .gsub(/\[[^\]]+\]\([^)]*\)/) { |match| match[/\[([^\]]+)\]/, 1] }
      .gsub(/[`*_~]/, "")
      .downcase
      .gsub(/[^\p{Alnum}\s-]/u, "")
      .strip
      .gsub(/\s+/, "-")
  end

  def repository_root
    Pathname.new(File.expand_path("../..", __dir__))
  end
end
