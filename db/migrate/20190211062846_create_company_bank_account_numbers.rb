class CreateCompanyBankAccountNumbers < ActiveRecord::Migration[5.0]
  def change
    create_table :company_bank_account_numbers do |t|
      t.references :company_bank, foreign_key: true, index: false
      t.string :account_number

      t.timestamps
    end
    add_index :company_bank_account_numbers, [:company_bank_id, :account_number], unique: true, name: "index_cban_on_company_bank_id_and_account_number"
  end
end
