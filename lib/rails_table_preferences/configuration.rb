# frozen_string_literal: true

module RailsTablePreferences
  class Configuration
    attr_accessor :table_name, :user_class_name, :user_foreign_key

    def initialize
      @table_name = "table_preferences"
      @user_class_name = "User"
      @user_foreign_key = "user_id"
    end
  end
end
