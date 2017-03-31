class AddIndexToNumberOnAccountPayables < ActiveRecord::Migration[5.0]
  def change
    add_index :account_payables, :number, :unique => true
  end
end
