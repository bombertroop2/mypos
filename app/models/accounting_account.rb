class AccountingAccount < ApplicationRecord
  belongs_to :category, class_name: "AccountingAccountCategory",  foreign_key: :category_id
  has_many :accounting_account_saldos
  validates :code, :description, :category_id, :classification, presence: true
  validates :code, :description, uniqueness: true

  default_scope {joins(:category).select("accounting_accounts.*, accounting_account_categories.name AS cat_name") }
  scope :classifications, -> (q=1) {  where(classification: q )} 

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
end
