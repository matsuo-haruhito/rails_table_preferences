# frozen_string_literal: true

module RailsTablePreferences
  class Configuration
    attr_accessor :table_name,
                  :user_class_name,
                  :user_foreign_key,
                  :parent_controller_class_name,
                  :current_user_method,
                  :mount_path

    def initialize
      @table_name = "table_preferences"
      @user_class_name = "User"
      @user_foreign_key = "user_id"
      @parent_controller_class_name = "ApplicationController"
      @current_user_method = :current_user
      @mount_path = "/rails_table_preferences"
    end
  end
end
