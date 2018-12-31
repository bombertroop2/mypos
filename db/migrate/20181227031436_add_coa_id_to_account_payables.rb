class AddCoaIdToAccountPayables < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payables, :coa_id, :integer, index: true
  end
end
