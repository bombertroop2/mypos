class CreateAccountingAccountSaldos < ActiveRecord::Migration[5.0]
  def change
    create_table :accounting_account_saldos do |t|
      t.integer :coa_id
      t.float :saldo
      t.string :year

      t.timestamps
    end
  end
end
