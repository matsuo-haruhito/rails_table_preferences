# frozen_string_literal: true

namespace :rails_table_preferences do
  namespace :legacy do
    desc "Import legacy ColumnAdjustment records into table_preferences"
    task import_column_adjustments: :environment do
      dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false))
      default_user = if ENV["USER_ID"].present?
                       RailsTablePreferences.configuration.user_class_name.constantize.find_by(id: ENV["USER_ID"])
                     end

      result = RailsTablePreferences::LegacyColumnAdjustmentImporter.new(
        default_user: default_user,
        dry_run: dry_run
      ).call

      puts "Rails Table Preferences legacy import"
      puts "dry_run: #{dry_run}"
      puts "created: #{result.created}"
      puts "updated: #{result.updated}"
      puts "skipped: #{result.skipped}"
      puts "imported: #{result.imported}"
    end
  end
end
