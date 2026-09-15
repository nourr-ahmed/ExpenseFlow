class CreateCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.decimal :auto_approve_limit, null: false, default: 0, precision: 10, scale: 2
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :categories, :name, unique: true
  end
end
