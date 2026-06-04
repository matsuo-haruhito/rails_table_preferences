# frozen_string_literal: true

require "spec_helper"
require "pathname"
require "rails_table_preferences/package_verifier"

RSpec.describe "Required documentation local links" do
  it "keeps repository-local links from package entrypoint docs resolvable" do
    missing_links = docs_link_guard_paths.flat_map { |path| missing_local_link_targets(path) }

    expect(missing_links).to eq([])
  end

  def docs_link_guard_paths
    markdown_required_paths = RailsTablePreferences::PackageVerifier::REQUIRED_PATHS.grep(/\A(?:README\.md|docs\/.*\.md)\z/)

    (["README.md", "docs/index.md"] + markdown_required_paths).uniq
  end

  def missing_local_link_targets(path)
    content = strip_fenced_code(File.read(repository_root.join(path)))

    markdown_link_targets(content).filter_map do |target|
      local_target = local_file_target(target)
      next unless local_target

      resolved_target = resolve_link_target(path, local_target)
      next if resolved_target.to_s.start_with?("#{repository_root}/") && File.exist?(resolved_target)

      "#{path} -> #{target} (missing #{resolved_target.relative_path_from(repository_root)})"
    end
  end

  def repository_root
    @repository_root ||= Pathname.new(File.expand_path("../..", __dir__))
  end

  def strip_fenced_code(content)
    content.gsub(/^```.*?^```[ \t]*$/m, "")
  end

  def markdown_link_targets(content)
    inline_targets = content.scan(/!?\[[^\]\n]*\]\((<[^>]+>|[^)\s]+)(?:\s+["'][^"']*["'])?\)/).flatten
    reference_targets = content.scan(/^\s*\[[^\]]+\]:\s*(<[^>]+>|\S+)/).flatten

    inline_targets + reference_targets
  end

  def local_file_target(target)
    normalized_target = target.to_s.strip.delete_prefix("<").delete_suffix(">")
    file_target = normalized_target.split("#", 2).first

    return nil if file_target.empty?
    return nil if normalized_target.start_with?("#")
    return nil if normalized_target.match?(/\A(?:[a-z][a-z0-9+.-]*:|\/\/)/i)

    decode_percent_escapes(file_target)
  end

  def decode_percent_escapes(target)
    target.gsub(/%[0-9A-Fa-f]{2}/) { |escape| escape[1, 2].to_i(16).chr }
  end

  def resolve_link_target(source_path, target)
    relative_target = if target.start_with?("/")
      target.delete_prefix("/")
    else
      Pathname.new(source_path).dirname.join(target).to_s
    end

    repository_root.join(relative_target).cleanpath
  end
end
