class CounterEventWarehouse < ApplicationRecord
	belongs_to :counter_event
	belongs_to :warehouse
	audited associated_with: :counter_event, on: [:create, :update]


  YES_OR_NO = [
    ["Yes", "yes"],
    ["No", "no"]
  ]

  validates :warehouse_id, presence: true
  validates :counter_event_id, presence: true
  
  before_destroy :delete_tracks


  private
  
  def warehouse_is_active
    warehouse_id = self.warehouse_id rescue nil
    errors.add(:base, "Sorry, warehouse is not active") if warehouse_id.present? && Warehouse.select("1 AS one").where(id: warehouse_id).where(["warehouses.is_active = ?", true]).blank?
  end

  
  def activable
    if is_active_changed? && persisted?
      cashier_opened = CashierOpening.joins(:warehouse).select("1 AS one").where(["warehouse_id = ? AND DATE(open_date) = ? AND closed_at IS NULL AND DATE(open_date) >= ? AND DATE(open_date) <= ? AND warehouses.is_active = ?", warehouse_id, Date.current, event.start_date_time.to_date, event.end_date_time.to_date, true]).present?
      errors.add(:base, "Please close some cashiers and try again") if cashier_opened
    end
  end
        
  #            def delete_old_products
  #              event_products.select(:id).destroy_all
  #            end

  def delete_tracks
    audits.destroy_all
  end

end
