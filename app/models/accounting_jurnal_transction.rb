class AccountingJurnalTransction < ApplicationRecord
  has_many :details, class_name: "AccountingJurnalTransctionDetail", foreign_key: :transction_id

  scope :load_jurnals, -> {joins(details: [coa: :category] )}

  def self.use_setting(setting="cashin")
    AccountingAccountSetting.jurnal(setting)
  end

  def self.jurnals(jurnal="cashin")
    eval "AccountingJurnalTransction.#{jurnal}"
  end

  def self.cashin
    load_jurnals.where(queries(type_jurnal="cashin"))
  end

  def self.cashout
    load_jurnals.where(queries(type_jurnal="cashout"))
  end

   def self.queries(type_jurnal="cashin")
    return {accounting_account_categories: {classification: [1,4]}, accounting_jurnal_transction_details: {is_debit: true} } if type_jurnal.eql?("cashin") ||  type_jurnal.eql?("sales")
    return {accounting_account_categories: {classification: 1}, accounting_jurnal_transction_details: {is_debit: false} } if type_jurnal.eql?("cashout") || type_jurnal.eql?("payable")
  end
end
