class AccountingAccountSaldo < ApplicationRecord
  belongs_to :coa, class_name: "AccountingAccount", foreign_key: :coa_id

  default_scope {joins(:coa).select("accounting_accounts.code AS code, accounting_accounts.description AS name, accounting_account_saldos.*")}

  def self.generate_year_saldo
    year = Date.today.year
    coa_ids = where(year: year).select(:coa_id).map(&:coa_id)
    saldo = AccountingAccount.unscoped.select("accounting_accounts.id").where.not(id: coa_ids).map{|x| {coa_id: x.id, year: year, saldo: 0 }}
    create(saldo)
  end

  def self.years
    select(:year).map(&:year).uniq
  end

  def self.filters(q={})
    year = q[:year].present? ? q[:year] : Date.today.year
    if q[:filter].present?
      query = []
      ["description", "code"].each { |x| query << "accounting_accounts.#{x} ILIKE :filter"}
      return where(accounting_account_saldos: {year: year}).where(query.join(" OR "), filter: "%"+q[:filter]+"%")
    end
    return where(accounting_account_saldos: {year: year})
  end
end
