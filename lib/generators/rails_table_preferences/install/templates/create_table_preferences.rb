# frozen_string_literal: true

class CreateTablePreferences < ActiveRecord::Migration[7.0]
  def change
    create_table :table_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.string :table_key, null: false
      t.string :name, null: false, default: "default"
      t.json :settings, null: false
      t.boolean :default_flag, null: false, default: false
      t.timestamps
    end

    add_index :table_preferences, [:user_id, :table_key, :name], unique: true
    add_index :table_preferences, [:user_id, :table_key, :default_flag]
  end
end
