class AccountingJurnalTransction < ApplicationRecord
  has_many :details, class_name: "AccountingJurnalTransctionDetail", foreign_key: :transction_id, dependent: :destroy

  scope :load_jurnals, -> {joins(details: [coa: :category] )}
  scope :find_by_model, ->(model) {where(model_id: model.id, model_type: model.class.to_s).first}

  def self.find_by_model(model)
  end

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

  def set_detail_record_transaction(model)
    details.build(model.set_detail_coa_jurnal)
  end


  def detail_jurnals
    details.joins(:coa).select("accounting_accounts.code, accounting_accounts.description, accounting_jurnal_transction_details.*")
  end
end
