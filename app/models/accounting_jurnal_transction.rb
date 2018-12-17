class AccountingJurnalTransction < ApplicationRecord
  has_many :details, class_name: "AccountingJurnalTransctionDetail", foreign_key: :transction_id, dependent: :destroy

  scope :load_jurnals, -> {joins(details: [coa: :category] )}
  scope :find_by_model, ->(model) {where(model_id: model.id, model_type: model.class.to_s).first}

  def self.year_and_month_queries(year=Date.today.year, month=Date.today.month)
    where("extract(year  from accounting_jurnal_transctions.created_at) = ? AND extract(month  from accounting_jurnal_transctions.created_at) = ?", year, month)
  end

  def self.total_query(is_debit='t')
    "SUM(Case
            When accounting_jurnal_transction_details.is_debit='#{is_debit}' Then accounting_jurnal_transction_details.total
            ELse 0
          END)"
  end

  def self.use_setting(setting="cashin")
    AccountingAccountSetting.jurnal(setting)
  end

  def self.jurnals(jurnal="cashin")
    eval "AccountingJurnalTransction.year_and_month_queries.#{jurnal}"
  end

  def self.cashin
    load_jurnals.where(queries(type_jurnal="cashin"))
  end

  def self.cashout
    load_jurnals.where(queries(type_jurnal="cashout"))
  end

  def self.total(type_jurnal)
    joins(:details).select("#{total_query('t')} AS total_debit, #{total_query('f')} AS total_credit").year_and_month_queries
    .where(type_jurnal: type_jurnal).to_a.first.attributes.to_hash rescue {total_debit: 0.0, total_credit: 0.0}
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
