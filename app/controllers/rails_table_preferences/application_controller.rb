# frozen_string_literal: true

module RailsTablePreferences
  class ApplicationController < RailsTablePreferences.configuration.parent_controller_class_name.constantize
    private

    def table_preferences_current_user
      public_send(RailsTablePreferences.configuration.current_user_method)
    end
  end
end
