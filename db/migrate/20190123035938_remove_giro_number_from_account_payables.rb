class RemoveGiroNumberFromAccountPayables < ActiveRecord::Migration[5.0]
  def change
    remove_column :account_payables, :giro_number, :string
  end
end
