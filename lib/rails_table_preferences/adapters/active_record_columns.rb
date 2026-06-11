# frozen_string_literal: true

module RailsTablePreferences
  module Adapters
    class ActiveRecordColumns
      DEFAULT_IGNORED_COLUMNS = %w[
        id
        created_at
        updated_at
        lock_version
      ].freeze

      def self.call(model:, only: nil, except: nil, include_id: false, include_associations: true)
        new(
          model: model,
          only: only,
          except: except,
          include_id: include_id,
          include_associations: include_associations
        ).call
      end

      def initialize(model:, only: nil, except: nil, include_id: false, include_associations: true)
        @model = model
        @only = Array(only).presence&.map(&:to_s)
        @except = Array(except).map(&:to_s)
        @include_id = ActiveModel::Type::Boolean.new.cast(include_id)
        @include_associations = ActiveModel::Type::Boolean.new.cast(include_associations)
      end

      def call
        (attribute_columns + association_columns).filter_map do |column|
          normalized = RailsTablePreferences::Adapters::ColumnLike.call(column)
          next if normalized["ignored"] == true

          normalized.except("ignored")
        end
      end

      private

      attr_reader :model, :only, :except, :include_id, :include_associations

      def attribute_columns
        candidate_attribute_names.map do |name|
          RailsTablePreferences::ColumnDefinition.new(
            key: name,
            model: model,
            filter: filter_for_attribute(name),
            sortable: sortable_attribute?(name)
          )
        end
      end

      def candidate_attribute_names
        names = Array(model.attribute_names)
        names &= only if only
        names.reject { |name| ignored_attribute?(name) }
      end

      def ignored_attribute?(name)
        return true if except.include?(name)
        return false if include_id && name == "id"

        DEFAULT_IGNORED_COLUMNS.include?(name)
      end

      def association_columns
        return [] unless include_associations
        return [] unless model.respond_to?(:reflect_on_all_associations)

        model.reflect_on_all_associations(:belongs_to).filter_map do |reflection|
          foreign_key = reflection.foreign_key.to_s
          next unless model.attribute_names.include?(foreign_key)
          next if except.include?(reflection.name.to_s)
          next if only && !only.include?(reflection.name.to_s)

          RailsTablePreferences::ColumnDefinition.new(
            key: reflection.name,
            model: model,
            filter: filter_for_association(reflection),
            sortable: false
          )
        end
      end

      def filter_for_attribute(name)
        if enum_attribute?(name)
          { type: "select", options: model.defined_enums.fetch(name).keys }
        else
          case attribute_type(name)
          when :boolean
            { type: "boolean" }
          when :date, :datetime, :time
            { type: "date" }
          when :integer, :decimal, :float
            { type: "number" }
          else
            { type: "text" }
          end
        end
      end

      def filter_for_association(reflection)
        {
          type: "association",
          association: reflection.name.to_s,
          foreign_key: reflection.foreign_key.to_s,
          class_name: reflection.class_name
        }
      end

      def sortable_attribute?(name)
        !enum_attribute?(name)
      end

      def enum_attribute?(name)
        model.respond_to?(:defined_enums) && model.defined_enums.key?(name)
      end

      def attribute_type(name)
        return unless model.respond_to?(:type_for_attribute)

        model.type_for_attribute(name)&.type
      end
    end
  end
end
