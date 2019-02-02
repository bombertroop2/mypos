class AddBeginningOfAccountPayableCreatingToGeneralVariables < ActiveRecord::Migration[5.0]
  def change
    add_column :general_variables, :beginning_of_account_payable_creating, :string, default: "Closed/Finish"
  end
end
