class CreateAccountingJurnalTransctionDetails < ActiveRecord::Migration[5.0]
  def change
    create_table :accounting_jurnal_transction_details do |t|
      t.integer :transction_id
      t.integer :coa_id
      t.boolean :is_debit
      t.decimal :total, precision: 10, scale: 2

      t.timestamps
    end
  end
end
