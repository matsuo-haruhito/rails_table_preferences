# frozen_string_literal: true

RailsTablePreferences.configure do |config|
  # Stores table preferences in the host application's primary database.
  config.table_name = "table_preferences"

  # Configure this when your application uses a model other than User to own preferences.
  #
  # The value may be a String or Symbol, singular or plural:
  #   config.owner_model = :customers # => Customer / customer_id
  #   config.owner_model = "clients"  # => Client / client_id
  #   config.owner_model = :account   # => Account / account_id
  #
  # Backward-compatible aliases are also available:
  #   config.user_class_name = "User"
  #   config.user_model = :users
  #   config.account_model = :accounts
  config.owner_model = :<%= owner_model %>

  # Override only when the default foreign key is not correct.
  # By default this follows owner_model, for example Customer => customer_id.
  # config.owner_foreign_key = :<%= owner_foreign_key %>

  # The engine controller inherits from this class and calls this method.
  config.parent_controller_class_name = "ApplicationController"
  config.current_user_method = :current_user

  # Keep this in sync with the path used to mount RailsTablePreferences::Engine.
  config.mount_path = "/rails_table_preferences"

  # Override this to render an application-owned editor partial.
  # The default partial can be copied with:
  #   bin/rails generate rails_table_preferences:views
  config.editor_partial = "rails_table_preferences/editor"
end
