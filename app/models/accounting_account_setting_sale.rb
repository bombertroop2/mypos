class AccountingAccountSettingSale < AccountingAccountSetting
  validates :coa_id, presence: true
  validates :coa_id, uniqueness: true
end
