# frozen_string_literal: true

module RailsTablePreferences
  class ApplicationController < RailsTablePreferences.configuration.parent_controller_class_name.constantize
    private

    def table_preferences_current_user
      send(RailsTablePreferences.configuration.current_user_method)
    end

    def table_preferences_scope_context
      method_name = RailsTablePreferences.configuration.scope_context_method
      return {} if method_name.blank?
      return {} unless respond_to?(method_name, true)

      context = send(method_name)
      context.respond_to?(:to_h) ? context.to_h : {}
    end
  end
end
