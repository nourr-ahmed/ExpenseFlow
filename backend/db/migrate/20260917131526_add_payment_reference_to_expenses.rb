class AddPaymentReferenceToExpenses < ActiveRecord::Migration[7.2]
  def change
    add_column :expenses, :payment_reference, :string
  end
end
