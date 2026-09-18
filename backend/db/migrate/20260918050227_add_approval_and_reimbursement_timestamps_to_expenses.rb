class AddApprovalAndReimbursementTimestampsToExpenses < ActiveRecord::Migration[7.2]
  def change
    add_column :expenses, :approved_at, :datetime
    add_column :expenses, :reimbursed_at, :datetime
  end
end
