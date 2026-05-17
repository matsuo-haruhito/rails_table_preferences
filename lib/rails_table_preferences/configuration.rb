# frozen_string_literal: true

require "active_support/inflector"

module RailsTablePreferences
  class Configuration
    LABEL_RESOLUTION_RULE_ALIASES = {
      explicit_label: :label,
      explicit_i18n_key: :i18n_key,
      db_comment: :column_comment,
      db_column_comment: :column_comment,
      active_record_i18n: :activerecord_attribute_i18n,
      active_record_attribute_i18n: :activerecord_attribute_i18n,
      activerecord_i18n: :activerecord_attribute_i18n,
      active_model_i18n: :activemodel_attribute_i18n,
      active_model_attribute_i18n: :activemodel_attribute_i18n,
      activemodel_i18n: :activemodel_attribute_i18n,
      attributes_i18n: :attribute_i18n,
      global_attribute_i18n: :attribute_i18n
    }.freeze

    VALID_LABEL_RESOLUTION_RULES = %i[
      label
      i18n_key
      column_comment
      activerecord_attribute_i18n
      activemodel_attribute_i18n
      attribute_i18n
      humanize
      key
    ].freeze

    UNRESOLVED_LABEL_BEHAVIOR_ALIASES = {
      ignore: :hide,
      ignored: :hide,
      hidden: :hide,
      show_key: :key
    }.freeze

    VALID_UNRESOLVED_LABEL_BEHAVIORS = %i[hide humanize key].freeze

    attr_accessor :table_name,
                  :parent_controller_class_name,
                  :current_user_method,
                  :scope_context_method,
                  :mount_path,
                  :editor_partial

    attr_reader :user_class_name,
                :user_foreign_key,
                :label_resolution,
                :unresolved_label_behavior

    def initialize
      @table_name = "table_preferences"
      @user_class_name = "User"
      @user_foreign_key = "user_id"
      @user_foreign_key_explicit = false
      @parent_controller_class_name = "ApplicationController"
      @current_user_method = :current_user
      @scope_context_method = nil
      @mount_path = "/rails_table_preferences"
      @editor_partial = "rails_table_preferences/editor"
      @label_resolution = %i[label i18n_key column_comment]
      @unresolved_label_behavior = :hide
    end

    def label_resolution=(value)
      rules = Array(value).map { |rule| normalize_label_resolution_rule(rule) }
      @label_resolution = rules
    end

    def unresolved_label_behavior=(value)
      behavior = normalize_unresolved_label_behavior(value)
      @unresolved_label_behavior = behavior
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

    def normalize_label_resolution_rule(value)
      normalized = value.to_s.strip.downcase.tr(" -", "__").to_sym
      normalized = LABEL_RESOLUTION_RULE_ALIASES.fetch(normalized, normalized)
      return normalized if VALID_LABEL_RESOLUTION_RULES.include?(normalized)

      raise ArgumentError, "Unsupported label resolution rule: #{value.inspect}"
    end

    def normalize_unresolved_label_behavior(value)
      normalized = value.to_s.strip.downcase.tr(" -", "__").to_sym
      normalized = UNRESOLVED_LABEL_BEHAVIOR_ALIASES.fetch(normalized, normalized)
      return normalized if VALID_UNRESOLVED_LABEL_BEHAVIORS.include?(normalized)

      raise ArgumentError, "Unsupported unresolved label behavior: #{value.inspect}"
    end

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