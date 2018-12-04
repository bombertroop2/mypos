class CreateAccountingAccountSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :accounting_account_settings do |t|
      t.integer :coa_id
      t.string :type
      t.boolean :is_debit

      t.timestamps
    end
  end
end
