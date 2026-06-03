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
      RailsTablePreferences::PackageVerifier.summary_lines(result).each { |line| warn line }

      unless result[:missing].empty?
        warn "Missing files:"
        result[:missing].each { |path| warn "  - #{path}" }
      end

      unless result[:missing_package_export_targets].empty?
        warn "Missing package export targets:"
        result[:missing_package_export_targets].each do |export_target|
          warn "  - #{export_target.fetch(:export)} -> #{export_target.fetch(:target)}"
        end
      end

      unless result[:missing_package_internal_imports].empty?
        warn "Missing package internal JavaScript imports:"
        result[:missing_package_internal_imports].each do |missing_import|
          warn "  - #{missing_import.fetch(:export)} #{missing_import.fetch(:entrypoint)} imports " \
            "#{missing_import.fetch(:import)} -> #{missing_import.fetch(:target)}"
        end
      end

      unless result[:package_json_errors].empty?
        warn "Package metadata errors:"
        result[:package_json_errors].each { |error| warn "  - #{error}" }
      end

      abort "Package verification failed."
    end
  end
end

task test: :spec
task default: :spec
