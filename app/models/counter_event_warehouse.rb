class CounterEventWarehouse < ApplicationRecord
	belongs_to :counter_event
	belongs_to :warehouse
  
	audited associated_with: :counter_event, on: [:create, :update]


  validates :warehouse_id, presence: true
  validate :warehouse_is_active
  
  before_create :set_is_active_as_nil
  before_destroy :delete_tracks


  private
  
  def set_is_active_as_nil
    self.is_active = nil
  end
  
  def warehouse_is_active
    warehouse_id = self.warehouse_id rescue nil
    errors.add(:base, "Sorry, warehouse is not active") if warehouse_id.present? && Warehouse.counter.select("1 AS one").where(id: warehouse_id).where(["warehouses.is_active = ?", true]).blank?
  end
          
  #            def delete_old_products
  #              event_products.select(:id).destroy_all
  #            end

  def delete_tracks
    audits.destroy_all
  end

end
