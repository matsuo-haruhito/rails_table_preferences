# frozen_string_literal: true

module RailsTablePreferences
  class Preference < ApplicationRecord
    OWNER_SCOPE_TYPE = "owner"
    SHARED_SCOPE_TYPE = "shared"
    ROLE_SCOPE_TYPE = "role"
    ORGANIZATION_SCOPE_TYPE = "organization"
    VALID_SCOPE_TYPES = [OWNER_SCOPE_TYPE, SHARED_SCOPE_TYPE, ROLE_SCOPE_TYPE, ORGANIZATION_SCOPE_TYPE].freeze

    self.table_name = RailsTablePreferences.configuration.table_name

    belongs_to :user,
               class_name: RailsTablePreferences.configuration.user_class_name,
               foreign_key: RailsTablePreferences.configuration.user_foreign_key,
               inverse_of: false,
               optional: true

    validates :table_key, presence: true
    validates :name, presence: true
    validates :settings, presence: true
    validates :scope_type, presence: true, inclusion: { in: VALID_SCOPE_TYPES }
    validates :scope_key, presence: true, if: :named_scope?
    validates RailsTablePreferences.configuration.user_foreign_key, presence: true, if: :owner_scope?
    validates :name, uniqueness: { scope: [:scope_type, :scope_key, RailsTablePreferences.configuration.user_foreign_key, :table_key] }

    scope :for_user, ->(user) { where(scope_type: OWNER_SCOPE_TYPE, RailsTablePreferences.configuration.user_foreign_key => user) }
    scope :shared, -> { where(scope_type: SHARED_SCOPE_TYPE) }
    scope :for_role, ->(role_key) { where(scope_type: ROLE_SCOPE_TYPE, scope_key: role_key.to_s) }
    scope :for_organization, ->(organization_key) { where(scope_type: ORGANIZATION_SCOPE_TYPE, scope_key: organization_key.to_s) }
    scope :for_scope, ->(scope_type, scope_key = nil) { where(scope_type: scope_type.to_s, scope_key: scope_key.presence&.to_s) }
    scope :for_table, ->(table_key) { where(table_key: table_key.to_s) }
    scope :defaults, -> { where(default_flag: true) }
    scope :available_to, ->(user:, scope_context: {}) do
      context = scope_context || {}
      relation = none
      relation = relation.or(for_user(user)) if user
      relation = relation.or(shared)
      Array(context[:roles] || context["roles"]).each do |role_key|
        relation = relation.or(for_role(role_key)) if role_key.present?
      end
      organization_key = context[:organization] || context["organization"] || context[:organization_key] || context["organization_key"]
      relation = relation.or(for_organization(organization_key)) if organization_key.present?
      relation
    end

    before_validation :set_default_name, :set_default_settings, :set_default_scope_type

    def self.find_for(user:, table_key:, name: "default", scope_type: OWNER_SCOPE_TYPE, scope_key: nil)
      for_scope(scope_type, scope_key).where(RailsTablePreferences.configuration.user_foreign_key => scope_type.to_s == OWNER_SCOPE_TYPE ? user : nil).for_table(table_key).find_by(name: name.to_s)
    end

    def self.find_or_initialize_for(user:, table_key:, name: "default", scope_type: OWNER_SCOPE_TYPE, scope_key: nil)
      for_scope(scope_type, scope_key).where(RailsTablePreferences.configuration.user_foreign_key => scope_type.to_s == OWNER_SCOPE_TYPE ? user : nil).for_table(table_key).find_or_initialize_by(name: name.to_s)
    end

    def self.default_for(user:, table_key:, scope_context: {})
      available_to(user: user, scope_context: scope_context).for_table(table_key).defaults.order(Arel.sql(scope_priority_case), :name).first || find_for(user: user, table_key: table_key, name: "default")
    end

    def shared?
      scope_type == SHARED_SCOPE_TYPE
    end

    def owner_scope?
      scope_type.blank? || scope_type == OWNER_SCOPE_TYPE
    end

    def named_scope?
      [ROLE_SCOPE_TYPE, ORGANIZATION_SCOPE_TYPE].include?(scope_type)
    end

    def editable_by_owner?(owner)
      owner_scope? && user == owner
    end

    def scope_label
      case scope_type
      when OWNER_SCOPE_TYPE then "owner"
      when SHARED_SCOPE_TYPE then "shared"
      when ROLE_SCOPE_TYPE then "role:#{scope_key}"
      when ORGANIZATION_SCOPE_TYPE then "organization:#{scope_key}"
      else scope_type.to_s
      end
    end

    def self.scope_priority_case
      <<~SQL.squish
        CASE scope_type
        WHEN 'owner' THEN 0
        WHEN 'role' THEN 1
        WHEN 'organization' THEN 2
        WHEN 'shared' THEN 3
        ELSE 9
        END
      SQL
    end

    private

    def set_default_name
      self.name = "default" if name.blank?
    end

    def set_default_settings
      self.settings = { "columns" => [], "filters" => {}, "sorts" => [] } if settings.blank?
    end

    def set_default_scope_type
      self.scope_type = OWNER_SCOPE_TYPE if scope_type.blank?
    end
  end
end
