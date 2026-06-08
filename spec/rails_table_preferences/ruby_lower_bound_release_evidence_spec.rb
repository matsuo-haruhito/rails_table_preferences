# frozen_string_literal: true

require "pathname"

RSpec.describe "Ruby lower-bound release evidence" do
  def repository_root
    Pathname.new(File.expand_path("../..", __dir__))
  end

  it "keeps the Rails 7.0 CI lane aligned with the Ruby 3.1 package lower bound" do
    gemspec = File.read(repository_root.join("rails_table_preferences.gemspec"))
    workflow = File.read(repository_root.join(".github/workflows/ci.yml"))
    support_matrix = File.read(repository_root.join("docs/support_matrix.md"))
    release_checklist = File.read(repository_root.join("docs/release_checklist.md"))

    expect(gemspec).to include('spec.required_ruby_version = ">= 3.1"')
    expect(gemspec).to include('spec.add_dependency "rails", ">= 7.0", "< 9.0"')

    rails_7_0_matrix_entry = /rails:\s*"7\.0"\s+gemfile:\s*gemfiles\/rails_7_0\.gemfile\s+ruby-version:\s*"3\.1"/
    expect(workflow).to match(rails_7_0_matrix_entry)

    expect(support_matrix).to include("| Ruby | 3.1 or later |")
    expect(support_matrix).to include(
      "| PR Rails compatibility (7.0) | 3.1 | `gemfiles/rails_7_0.gemfile` | Lower-bound Rails 7.0 regression check |"
    )

    expect(release_checklist).to include("BUNDLE_GEMFILE=gemfiles/rails_7_0.gemfile bundle exec rspec")
    expect(release_checklist).to include(
      "These Rails 7.0 / 7.1 / 7.2 / 8.0 checks match the current representative compatibility matrix."
    )
  end
end
