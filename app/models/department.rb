class Department < ApplicationRecord
  audited on: [:create, :update]
  validates :code, :name, presence: true
  validate :company_exist
  belongs_to :company
  before_validation :upcase_code
  before_destroy :delete_tracks

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
end
