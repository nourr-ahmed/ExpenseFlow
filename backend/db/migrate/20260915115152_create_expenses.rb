class CreateExpenses < ActiveRecord::Migration[7.2]
  def change
    create_table :expenses do |t|
      t.string :title, null: false
      t.text :description
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.references :category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :spent_on, null: false
      t.string :status, null: false, default: "draft"
      t.timestamps
    end
    add_index :expenses, :spent_on
    add_index :expenses, :status
  end
end
