class PackingListItem < ApplicationRecord
  attr_accessor :attr_do_number, :attr_delivery_date, :attr_courier_id, :attr_city_id, :attr_packing_list_date, :attr_courier_unit_id, :attr_quantity, :attr_received_date
  belongs_to :shipment
  belongs_to :packing_list
  
  before_validation :get_courier_unit, :remove_unused_unit_value
  
  validates :shipment_id, :presence => true
  validates :weight, :presence => true, :if => proc{@courier_unit.name.eql?("Kilogram")}
  validates :volume, :presence => true, :if => proc{@courier_unit.name.eql?("Cubic")}
  validates :weight, :numericality => {:greater_than => 0}, :if => proc { |pli| pli.weight.present? && pli.weight_changed? && pli.weight.is_a?(Numeric) && @courier_unit.name.eql?("Kilogram") }
  validates :volume, :numericality => {:greater_than => 0}, :if => proc { |pli| pli.volume.present? && pli.volume_changed? && pli.volume.is_a?(Numeric) && @courier_unit.name.eql?("Cubic") }
  validate :shipment_available, :if => proc{|pli| pli.shipment_id.present? && pli.shipment_id_changed?}
  validate :shipment_delivery_date_valid, :if => proc{|pli|pli.attr_packing_list_date.present? && @shipment.present?}
  validate :shipment_received_date_valid, :if => proc{|pli|pli.attr_packing_list_date.present? && @shipment.present?}
  
  after_create :update_quantity, :mark_shipment_packed_up
  after_destroy :unmark_packed_up_shipment
  
  private
  
  def unmark_packed_up_shipment
    shipment.update_column(:is_packed_up, false)
  end
  
  def mark_shipment_packed_up
    @shipment.update_column(:is_packed_up, true)
  end
  
  def update_quantity
    pl = PackingList.select(:id, :total_quantity).where(id: packing_list_id).first
    pl.with_lock do
      pl.total_quantity = pl.total_quantity.to_i + @shipment.quantity
      pl.total_volume = pl.total_volume.to_f + volume if @courier_unit.name.eql?("Cubic")
      pl.total_weight = pl.total_weight.to_f + weight if @courier_unit.name.eql?("Kilogram")
      pl.save validate: false
    end
  end
  
  def remove_unused_unit_value
    self.volume = nil if @courier_unit.name.eql?("Kilogram")
    self.weight = nil if @courier_unit.name.eql?("Cubic")
  end
  
  def get_courier_unit
    @courier_unit = CourierUnit.select(:name).find(attr_courier_unit_id)
  end
  
  def shipment_available
    courier = Courier.select(:status).find(attr_courier_id)
    if courier.status.eql?("External")
      errors.add(:shipment_id, "does not exist!") if attr_city_id.present? && (@shipment = Shipment.select(:id, :delivery_date, :quantity, :is_packed_up, :received_date).joins(:order_booking => :destination_warehouse).where(:id => shipment_id, :is_packed_up => false).where(["warehouses.city_id = ?", attr_city_id]).first).blank?
    else
      errors.add(:shipment_id, "does not exist!") if (@shipment = Shipment.select(:id, :delivery_date, :quantity, :is_packed_up, :received_date).where(:id => shipment_id, :is_packed_up => false).first).blank?
    end
  end
  
  def shipment_delivery_date_valid
    errors.add(:attr_delivery_date, "must be before or equal to #{attr_packing_list_date}") if @shipment.delivery_date > attr_packing_list_date.to_date
  end

  def shipment_received_date_valid
    errors.add(:attr_received_date, "must be after or equal to #{attr_packing_list_date}") if @shipment.received_date.present? && attr_packing_list_date.to_date > @shipment.received_date
  end
end
