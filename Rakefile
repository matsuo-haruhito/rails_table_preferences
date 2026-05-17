# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require_relative "lib/rails_table_preferences/package_verifier"
require_relative "lib/rails_table_preferences/version"

RSpec::Core::RakeTask.new(:spec)

namespace :package do
  desc "Verify that the built gem package includes required runtime, generator, asset, and documentation files"
  task :verify do
    gem_path = Dir[File.join(__dir__, "pkg", "rails_table_preferences-*.gem")].max_by { |path| File.mtime(path) }
    abort "No built gem found. Run `bundle exec rake build` first." unless gem_path

    result = RailsTablePreferences::PackageVerifier.call(gem_path: gem_path)

    if result[:ok]
      puts "Package verification passed: #{File.basename(gem_path)}"
    else
      warn "Package verification failed: #{File.basename(gem_path)}"
      warn "Missing files:"
      result[:missing].each { |path| warn "  - #{path}" }
      abort "Package verification failed."
    end
  end
end

task test: :spec
task default: :spec
