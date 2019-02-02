class AddBeginningOfAccountPayableCreatingToAccountPayables < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payables, :beginning_of_account_payable_creating, :string, default: "Closed/Finish"
  end
end
