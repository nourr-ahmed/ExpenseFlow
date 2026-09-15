class CreateExpenseHistories < ActiveRecord::Migration[7.2]
  def change
    create_table :expense_histories do |t|
      t.references :expense, null: false, foreign_key: true
      t.string :from_status
      t.string :to_status, null: false
      t.references :actor_user, foreign_key: { to_table: :users }
      t.string :comment
      t.datetime :created_at, null: false
    end

    add_check_constraint :expense_histories,
    "to_status != 'rejected' OR (comment IS NOT NULL AND comment != '')",
    name: "check_rejection_requires_comment"
  end
end
