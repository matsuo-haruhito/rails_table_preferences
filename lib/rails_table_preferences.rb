# frozen_string_literal: true

require "rails_table_preferences/version"
require "rails_table_preferences/renderer_registry"
require "rails_table_preferences/configuration"
require "rails_table_preferences/column_definition"
require "rails_table_preferences/settings_normalizer"
require "rails_table_preferences/adapters/column_like"
require "rails_table_preferences/adapters/active_record_columns"
require "rails_table_preferences/table_profile"
require "rails_table_preferences/table_state"
require "rails_table_preferences/value_resolver"
require "rails_table_preferences/export_payload"
require "rails_table_preferences/package_verifier"
require "rails_table_preferences/legacy_column_adjustment_importer"
require "rails_table_preferences/adapters/ransack"
require "rails_table_preferences/adapters/controller_params"
require "rails_table_preferences/engine"

module RailsTablePreferences
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end
  end
end
