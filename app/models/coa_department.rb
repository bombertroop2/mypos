class CoaDepartment < ApplicationRecord
  audited on: [:create, :update]
  belongs_to :department
  belongs_to :coa
  belongs_to :warehouse
  validates :department_id, :coa_id, :warehouse_id, :location, presence: true
  validate :department_exist, :coa_exist, :warehouse_exist
  before_destroy :delete_tracks

  private
  def delete_tracks
    audits.destroy_all
  end

  def department_exist
    errors.add(:department_id, "does not exist!") if department_id_changed? && Department.select("1 AS one").where(:id => department_id).blank?
  end

  def coa_exist
    errors.add(:coa_id, "does not exist!") if coa_id_changed? && Coa.select("1 AS one").where(:id => coa_id).blank?
  end

  def warehouse_exist
    errors.add(:warehouse_id, "does not exist!") if warehouse_id_changed? && Warehouse.select("1 AS one").where(:id => warehouse_id).blank?
  end

end
