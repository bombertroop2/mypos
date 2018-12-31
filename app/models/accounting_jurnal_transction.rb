class AccountingJurnalTransction < ApplicationRecord
  has_many :details, class_name: "AccountingJurnalTransctionDetail", foreign_key: :transction_id, dependent: :destroy
  belongs_to :warehouse
  belongs_to :model, polymorphic: true

  scope :load_jurnals, -> {joins(details: [coa: :category] )}
  scope :find_by_model, ->(model) {where(model_id: model.id, model_type: model.class.to_s).first}
  scope :warehouse_is_central, -> {joins(:warehouse).where("warehouses.warehouse_type = ? ", "central")}
  # scope :only_cash_disbursements, -> {collection_filed_group_by_model_type.where(model_type: "CashDisbursement")}

  def self.year_and_month_queries(year=Date.today.year, month=Date.today.month)
    where("extract(year  from accounting_jurnal_transctions.created_at) = ? AND extract(month  from accounting_jurnal_transctions.created_at) = ?", year, month)
  end

  def self.total_query(is_debit='t')
    "SUM(Case
            When accounting_jurnal_transction_details.is_debit='#{is_debit}' Then accounting_jurnal_transction_details.total
            ELse 0
          END)"
  end

  def self.collection_filed_group_by_model_type
    joins(:warehouse)
    .select("0 as id,
    STRING_AGG(DISTINCT (accounting_jurnal_transctions.model_type), ', ' ) as model_type,
    STRING_AGG(DISTINCT (accounting_jurnal_transctions.model_type), ', ' ) as description,
    STRING_AGG(DISTINCT (warehouses.name), ', ' ) as name,
    array_agg(accounting_jurnal_transctions.id) as ids,
    array_agg(accounting_jurnal_transctions.model_id) as model_ids,
    (array_agg(accounting_jurnal_transctions.created_at ORDER BY accounting_jurnal_transctions.created_at DESC))[1] as created_at,
    (array_agg(accounting_jurnal_transctions.updated_at ORDER BY accounting_jurnal_transctions.updated_at DESC))[1] as updated_at")
    .where.not(warehouses: {warehouse_type: "central"}).distinct
    .group("accounting_jurnal_transctions.model_type, accounting_jurnal_transctions.warehouse_id").to_a
  end

  def detail_groups
    AccountingJurnalTransctionDetail.joins(:coa).where(accounting_jurnal_transction_details: {transction_id: self.ids})
    .select("accounting_jurnal_transction_details.coa_id,
      STRING_AGG(DISTINCT (accounting_accounts.code), ', ' ) as code,
      STRING_AGG(DISTINCT (accounting_accounts.description), ', ' ) as description,
      (array_agg(DISTINCT (accounting_jurnal_transction_details.is_debit)))[1] as is_debit,
      sum(accounting_jurnal_transction_details.total) as total,
      (array_agg(accounting_jurnal_transction_details.created_at ORDER BY accounting_jurnal_transction_details.created_at DESC))[1] as created_at,
      (array_agg(accounting_jurnal_transction_details.updated_at ORDER BY accounting_jurnal_transction_details.updated_at DESC))[1] as updated_at")
    .group("accounting_jurnal_transction_details.coa_id, accounting_jurnal_transction_details.is_debit").order("is_debit DESC")

  end

  def self.use_setting(setting="cashin")
    AccountingAccountSetting.jurnal(setting)
  end

  def self.jurnals(jurnal="cashin", warehouse_id=nil)
    eval "AccountingJurnalTransction.year_and_month_queries.#{jurnal}(warehouse_id)"
  end

  def self.cashin(warehouse_id)
    if warehouse_id.eql?(nil)
      load_jurnals.where(queries(type_jurnal="cashin")).warehouse_is_central.distinct.to_a +
      load_jurnals.where(queries(type_jurnal="cashin")).collection_filed_group_by_model_type
    else
      load_jurnals.where(queries(type_jurnal="cashin")).where(accounting_jurnal_transctions: {warehouse_id: warehouse_id}).distinct
    end
  end

  def self.cashout(warehouse_id)
    if warehouse_id.eql?(nil)
      load_jurnals.where(queries(type_jurnal="cashout")).warehouse_is_central.distinct.to_a +
      load_jurnals.where(queries(type_jurnal="cashout")).collection_filed_group_by_model_type
    else
      load_jurnals.where(queries(type_jurnal="cashout")).where(accounting_jurnal_transctions: {warehouse_id: warehouse_id}).distinct
    end
  end

  def self.total(type_jurnal, warehouse_id=nil)
    querie_filters = {type_jurnal: type_jurnal}
    querie_filters[:warehouse_id] = warehouse_id if !warehouse_id.eql?(nil)
    joins(:details).select("#{total_query('t')} AS total_debit, #{total_query('f')} AS total_credit").year_and_month_queries
    .where(querie_filters).to_a.first.attributes.to_hash rescue {total_debit: 0.0, total_credit: 0.0}
  end

  def self.queries(type_jurnal="cashin")
    return {accounting_accounts: {classification: [1,4]}, accounting_jurnal_transction_details: {is_debit: true} } if type_jurnal.eql?("cashin") ||  type_jurnal.eql?("sales")
    return {accounting_account_categories: {classification: 1}, accounting_jurnal_transction_details: {is_debit: false} } if type_jurnal.eql?("cashout") || type_jurnal.eql?("payable")
  end

  def group_description
    description.constantize.model_name.human + " transcation from " + name
  end

  def set_detail_record_transaction(model)
    details.build(model.set_detail_coa_jurnal)
  end

  def detail_jurnals
    details.joins(:coa)
    .select("accounting_accounts.code, accounting_accounts.description, accounting_jurnal_transction_details.*")
    .order("accounting_jurnal_transction_details.is_debit DESC")
  end

end
