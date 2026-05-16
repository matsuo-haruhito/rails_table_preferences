# frozen_string_literal: true

require_relative "lib/rails_table_preferences/version"

Gem::Specification.new do |spec|
  spec.name = "rails_table_preferences"
  spec.version = RailsTablePreferences::VERSION
  spec.authors = ["Haruhito Matsuo"]
  spec.email = ["matsuo@scrumsoftware.co.jp"]

  spec.summary = "User-specific table display preferences for Rails applications."
  spec.description = "Rails Table Preferences saves and restores user-specific table display settings such as column visibility, order, width, and truncation."
  spec.homepage = "https://github.com/matsuo-haruhito/rails_table_preferences"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"

  spec.files = Dir.chdir(__dir__) do
    Dir["{app,config,lib}/**/*", "LICENSE", "README.md"]
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0", "< 9.0"

  spec.add_development_dependency "rspec-rails", ">= 6.0"
  spec.add_development_dependency "sqlite3", ">= 1.6"
end
