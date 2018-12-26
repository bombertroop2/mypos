class AccountingJurnalTransctionDetail < ApplicationRecord
  belongs_to :transction, class_name: "AccountingJurnalTransction", foreign_key: :transction_id
  belongs_to :coa, class_name: "AccountingAccount", foreign_key: :coa_id


  def sum_group_total
    collection_total.inject(:+).to_f
  end

  def check_is_debit
    is_debits.uniq.firt rescue false
  end
end
