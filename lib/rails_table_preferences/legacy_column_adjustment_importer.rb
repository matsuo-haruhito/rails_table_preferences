# frozen_string_literal: true

module RailsTablePreferences
  class LegacyColumnAdjustmentImporter
    Result = Struct.new(:created, :updated, :skipped, keyword_init: true) do
      def imported
        created + updated
      end
    end

    def initialize(scope: nil, user_resolver: nil, default_user: nil, dry_run: false)
      @scope = scope || default_scope
      @user_resolver = user_resolver
      @default_user = default_user
      @dry_run = dry_run
    end

    def call
      result = Result.new(created: 0, updated: 0, skipped: 0)

      scope.find_each do |record|
        user = resolve_user(record)
        unless user
          result.skipped += 1
          next
        end

        attributes = preference_attributes(record, user)
        preference = Preference.find_or_initialize_for(
          user: user,
          table_key: attributes[:table_key],
          name: attributes[:name]
        )
        created = preference.new_record?
        preference.settings = attributes[:settings]
        preference.default_flag = attributes[:default_flag]

        unless dry_run
          preference.save!
        end

        created ? result.created += 1 : result.updated += 1
      rescue JSON::ParserError, ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid, NoMethodError
        result.skipped += 1
      end

      result
    end

    private

    attr_reader :scope, :user_resolver, :default_user, :dry_run

    def default_scope
      legacy_model.all
    end

    def legacy_model
      "ColumnAdjustment".constantize
    end

    def preference_attributes(record, user)
      {
        user: user,
        table_key: legacy_table_key(record),
        name: legacy_name(record),
        settings: legacy_settings(record),
        default_flag: false
      }
    end

    def legacy_table_key(record)
      record.respond_to?(:table_name) ? record.table_name.to_s : "default"
    end

    def legacy_name(record)
      name = record.respond_to?(:setting_name) ? record.setting_name : nil
      name.presence || "default"
    end

    def legacy_settings(record)
      value = record.respond_to?(:value) ? record.value : nil
      columns = parse_legacy_value(value)
      SettingsNormalizer.call("columns" => columns)
    end

    def parse_legacy_value(value)
      case value
      when String
        JSON.parse(value)
      when Array
        value
      when Hash
        value.fetch("columns", value.fetch(:columns, []))
      else
        []
      end
    end

    def resolve_user(record)
      return user_resolver.call(record) if user_resolver
      return default_user if default_user
      return record.user if record.respond_to?(:user) && record.user
      return record.create_user if record.respond_to?(:create_user) && record.create_user
      return configured_user_class.find_by(id: record.user_id) if record.respond_to?(:user_id) && record.user_id.present?
      return configured_user_class.find_by(id: record.create_user_id) if record.respond_to?(:create_user_id) && record.create_user_id.present?

      nil
    end

    def configured_user_class
      RailsTablePreferences.configuration.user_class_name.constantize
    end
  end
end
