class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.text :message, null: false
      t.boolean :read, null: false, default: false
      t.references :expense, null: false, foreign_key: true
      t.timestamps
    end
    add_index :notifications, [:user_id, :read]
  end
end
