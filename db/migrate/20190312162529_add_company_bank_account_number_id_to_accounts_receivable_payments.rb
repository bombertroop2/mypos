class AddCompanyBankAccountNumberIdToAccountsReceivablePayments < ActiveRecord::Migration[5.0]
  def change
    add_reference :accounts_receivable_payments, :company_bank_account_number, foreign_key: true, index: false
    add_index :accounts_receivable_payments, :company_bank_account_number_id, name: "index_arp_on_company_bank_account_number_id"
  end
end
