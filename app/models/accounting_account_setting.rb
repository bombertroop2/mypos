class AccountingAccountSetting < ApplicationRecord

  belongs_to :coa, class_name: "AccountingAccount", foreign_key: :coa_id

  default_scope {joins(:coa).select("accounting_account_settings.*, accounting_accounts.code AS code, accounting_accounts.description AS name") }

  def self.jurnal(type="Cash")
    model = "AccountingAccountSetting#{type.capitalize}".constantize
  end

  def self.filters(q={})
    p q
    if q[:filter].present?
      query = []
      ["description", "code"].each { |x| query << "accounting_accounts.#{x} ILIKE :filter"}
      return where(query.join(" OR "), filter: "%"+q[:filter]+"%")
    end
    return all
  end

  def coas
    AccountingAccount.select(:id, :description)
  end
end
