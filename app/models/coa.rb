class Coa < ApplicationRecord
  audited on: [:create, :update]
  validates :code, :name, :transaction_type, presence: true
  validate :code_not_changed, :transaction_type_not_changed, :transaction_type_available
  has_many :coa_departments, dependent: :restrict_with_error
  has_one :coa_department_relation, -> {select("1 AS one")}, class_name: "CoaDepartment"
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

  def coa_view
    "#{code} - #{transaction_type}"
  end

  private
  def delete_tracks
    audits.destroy_all
  end

  def upcase_code
    self.code = code.upcase.gsub(" ","").gsub("\t","")
  end

  def transaction_type_available
    Coa::TRANSACTION_TYPE.select{ |x| x[1] == transaction_type }.first.first
  rescue
    errors.add(:transaction_type, "does not exist!") if transaction_type.present?
  end

  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && coa_department_relation.present?
  end

  def transaction_type_not_changed
    errors.add(:transaction_type, "change is not allowed!") if transaction_type_changed? && persisted? && coa_department_relation.present?
  end

end
