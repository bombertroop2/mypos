class AccountingAccountCategory < ApplicationRecord
  has_many :accounting_accounts, foreign_key: :category_id
end
