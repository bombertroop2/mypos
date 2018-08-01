class Coa < ApplicationRecord
  audited on: [:create, :update]
  validates :code, :name, :company_id, :transaction_type, presence: true
  validate :company_exist, :transaction_type_available
  has_many :coa_departments
  belongs_to :company, -> {select("1 AS one")}
  before_validation :upcase_code
  before_destroy :delete_tracks

  TRANSACTION_TYPE = [
              ["BS - Beginning Stock", "BS"],
              ["PO - Purchase Order", "PO"],
              ["PR - Purchase Return", "PR"],
              ["DO - Delivery Order", "DO"],
              ["RW - Return to Warehouse", "RW"],
              ["RGO - Rolling Out", "RGO"],
              ["RGI - Rolling In", "RGI"],
              ["POS - Point Of Sales", "POS"],
              ["RET - POS Return", "RET"],
              ["SLK - Consignment Sales", "SLK"]
            ]

  def transaction_type_detail
    if transaction_type == "BS"
      return "BS - Beginning Stock"
    elsif transaction_type == "PO"
      return "PO - Purchase Order"
    elsif transaction_type == "PR"
      return "PR - Purchase Return"
    elsif transaction_type == "DO"
      return "DO - Delivery Order"
    elsif transaction_type == "RW"
      return "RW - Return to Warehouse"
    elsif transaction_type == "RGO"
      return "RGO - Rolling Out"
    elsif transaction_type == "RGI"
      return "RGI - Rolling In"
    elsif transaction_type == "POS"
      return "POS - Point Of Sales"
    elsif transaction_type == "RET"
      return "RET - POS Return"
    elsif transaction_type == "SLK"
      return "SLK - Consignment Sales"
    end
  end

  private
  def delete_tracks
    audits.destroy_all
  end

  def upcase_code
    self.code = code.upcase.gsub(" ","").gsub("\t","")
  end

  def company_exist
    errors.add(:company_id, "does not exist!") if company_id_changed? && Company.select("1 AS one").where(:id => company_id).blank?
  end

  def transaction_type_available
    Coa::TRANSACTION_TYPE.select{ |x| x[1] == transaction_type }.first.first
  rescue
    errors.add(:transaction_type, "does not exist!") if transaction_type.present?
  end

end