# frozen_string_literal: true

require "rails_table_preferences/version"
require "rails_table_preferences/configuration"
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
