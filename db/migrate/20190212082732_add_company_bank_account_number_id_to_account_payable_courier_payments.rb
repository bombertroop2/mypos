class AddCompanyBankAccountNumberIdToAccountPayableCourierPayments < ActiveRecord::Migration[5.0]
  def change
    add_reference :account_payable_courier_payments, :company_bank_account_number, foreign_key: true, index: false
    add_index :account_payable_courier_payments, :company_bank_account_number_id, name: "index_apcp_on_company_bank_account_number_id"
  end
end
