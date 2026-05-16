# frozen_string_literal: true

module RailsTablePreferences
  class Preference < ApplicationRecord
    self.table_name = RailsTablePreferences.configuration.table_name

    belongs_to :user,
               class_name: RailsTablePreferences.configuration.user_class_name,
               foreign_key: RailsTablePreferences.configuration.user_foreign_key,
               inverse_of: false

    validates :table_key, presence: true
    validates :name, presence: true
    validates :settings, presence: true
    validates :name, uniqueness: { scope: [RailsTablePreferences.configuration.user_foreign_key, :table_key] }

    scope :for_user, ->(user) { where(RailsTablePreferences.configuration.user_foreign_key => user) }
    scope :for_table, ->(table_key) { where(table_key: table_key.to_s) }
    scope :defaults, -> { where(default_flag: true) }

    before_validation :set_default_name, :set_default_settings

    def self.find_for(user:, table_key:, name: "default")
      for_user(user).for_table(table_key).find_by(name: name.to_s)
    end

    def self.find_or_initialize_for(user:, table_key:, name: "default")
      for_user(user).for_table(table_key).find_or_initialize_by(name: name.to_s)
    end

    private

    def set_default_name
      self.name = "default" if name.blank?
    end

    def set_default_settings
      self.settings = { "columns" => [], "filters" => {}, "sorts" => [] } if settings.blank?
    end
  end
end
