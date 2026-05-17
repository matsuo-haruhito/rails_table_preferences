# frozen_string_literal: true

class CreateTablePreferences < ActiveRecord::Migration[7.0]
  def change
    create_table :table_preferences do |t|
      t.references :<%= owner_foreign_key.delete_suffix("_id") %>, null: false, foreign_key: { to_table: :<%= owner_table_name %> }
      t.string :table_key, null: false
      t.string :name, null: false, default: "default"
      t.json :settings, null: false
      t.boolean :default_flag, null: false, default: false
      t.timestamps
    end

    add_index :table_preferences, [:<%= owner_foreign_key %>, :table_key, :name], unique: true, name: "idx_table_preferences_owner_table_name"
    add_index :table_preferences, [:<%= owner_foreign_key %>, :table_key, :default_flag], name: "idx_table_preferences_owner_table_default"
  end
end
