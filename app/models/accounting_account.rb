class AccountingAccount < ApplicationRecord
  belongs_to :category, class_name: "AccountingAccountCategory",  foreign_key: :category_id
  has_many :saldos, class_name: "AccountingAccountSaldo",  foreign_key: :coa_id
  validates :code, :description, :category_id, :classification, presence: true
  validates :code, :description, uniqueness: true

  default_scope {joins(:category).select("accounting_accounts.*, accounting_account_categories.name AS cat_name") }
  scope :classifications, -> (q=1) {  where(classification: q )}
  scope :select_on_view, -> { select("accounting_accounts.id, concat(accounting_accounts.code, ' ' ,accounting_accounts.description) AS description") }
  scope :category_cash_on_view, -> { select_on_view.where(accounting_accounts: {category_id: 1 }) }
  def self.filters(q={})
    if q[:filter].present?
      query = []
      ["description", "code"].each { |x| query << "accounting_accounts.#{x} ILIKE :filter"}
      return classifications( (q[:classification] || 1) ).where(query.join(" OR "), filter: "%"+q[:filter]+"%")
    end
    return classifications( (q[:classification] || 1))
  end

  def categories
    AccountingAccountCategory.select(:id, :name)
  end

  def classification_name
    CLASSIFICATIONS.select{|x| x[:id].eql?(classification)}.first[:name]
  end

  def code_parts
    codes = {}
    0.upto(code.size) do |x|
      codes["code_#{x}"] = code[x]
    end
    return codes
  end

  def last_3_code
    code_parts.last(3).to_i
  end

  def first_2_code
    code_parts.first(2).to_s
  end


end
