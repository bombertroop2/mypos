class ChangeTypeOfTotalOnAccountingTransactionDetails < ActiveRecord::Migration[5.0]
  def change
      change_column :accounting_jurnal_transction_details, :total, :decimal
  end
end
