class AccountingJurnalTransctionDetail < ApplicationRecord
  belongs_to :transction, class_name: "AccountingJurnalTransction", foreign_key: :transction_id
  belongs_to :coa, class_name: "AccountingAccount", foreign_key: :coa_id

end
