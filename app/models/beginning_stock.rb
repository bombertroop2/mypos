class BeginningStock < ApplicationRecord
  belongs_to :warehouse
  has_many :beginning_stock_months, dependent: :destroy
  
  validate :warehouse_is_active
  
  private
  
  def warehouse_is_active
    errors.add(:base, "Sorry, warehouse is not active") if Warehouse.select("1 AS one").where(id: warehouse_id).where(["warehouses.is_active = ?", true]).blank?
  end
end
