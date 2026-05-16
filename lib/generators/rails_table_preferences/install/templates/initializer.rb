# frozen_string_literal: true

RailsTablePreferences.configure do |config|
  # Stores table preferences in the host application's primary database.
  config.table_name = "table_preferences"

  # Configure these when your application uses a user model other than User.
  config.user_class_name = "User"
  config.user_foreign_key = "user_id"

  # The engine controller inherits from this class and calls this method.
  config.parent_controller_class_name = "ApplicationController"
  config.current_user_method = :current_user

  # Keep this in sync with the path used to mount RailsTablePreferences::Engine.
  config.mount_path = "/rails_table_preferences"
end
