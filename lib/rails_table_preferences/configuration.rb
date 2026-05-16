# frozen_string_literal: true

require "active_support/inflector"

module RailsTablePreferences
  class Configuration
    attr_accessor :table_name,
                  :parent_controller_class_name,
                  :current_user_method,
                  :mount_path

    attr_reader :user_class_name, :user_foreign_key

    def initialize
      @table_name = "table_preferences"
      @user_class_name = "User"
      @user_foreign_key = "user_id"
      @user_foreign_key_explicit = false
      @parent_controller_class_name = "ApplicationController"
      @current_user_method = :current_user
      @mount_path = "/rails_table_preferences"
    end

    def user_class_name=(value)
      @user_class_name = normalize_class_name(value)
      @user_foreign_key = default_foreign_key_for(@user_class_name) unless user_foreign_key_explicit?
    end

    def user_foreign_key=(value)
      @user_foreign_key = normalize_foreign_key(value)
      @user_foreign_key_explicit = true
    end

    def owner_model=(value)
      self.user_class_name = value
    end

    def user_model=(value)
      self.user_class_name = value
    end

    def account_model=(value)
      self.user_class_name = value
    end

    def owner_class_name
      user_class_name
    end

    def owner_class_name=(value)
      self.user_class_name = value
    end

    def owner_foreign_key
      user_foreign_key
    end

    def owner_foreign_key=(value)
      self.user_foreign_key = value
    end

    private

    def normalize_class_name(value)
      value.to_s.strip.classify
    end

    def normalize_foreign_key(value)
      value.to_s.strip.underscore
    end

    def default_foreign_key_for(class_name)
      class_name.to_s.foreign_key
    end

    def user_foreign_key_explicit?
      @user_foreign_key_explicit
    end
  end
end
