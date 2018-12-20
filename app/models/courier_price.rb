class CourierPrice < ApplicationRecord
  attr_accessor :attr_courier_id, :attr_courier_way_id
	audited associated_with: :courier_unit, on: [:create, :update]

  belongs_to :courier_unit
  belongs_to :city
  

  PRICE_TYPES = [
    ["Regular", "Regular"],
    ["Express", "Express"]
  ]
  
  validates :city_id, :effective_date, :price_type, :price, :attr_courier_id, :attr_courier_way_id, :courier_unit_id, presence: true
  validate :city_available, if: proc{|cp| cp.city_id.present? && cp.city_id_changed?}
    validates :effective_date, date: {after_or_equal_to: Proc.new { Date.current }, message: 'must be after or equal to today' }, if: proc {|cp| cp.effective_date.present? && cp.effective_date_changed?}
      validate :price_type_available, if: proc {|cp| cp.price_type.present? && cp.price_type_changed?}
        validates :price, numericality: {greater_than_or_equal_to: 1}, if: proc { |cp| cp.price.present? && cp.price_changed? && cp.price.is_a?(Numeric) }
          validate :courier_available, if: proc{|cp| cp.attr_courier_id.present?}
            validate :via_available, if: proc{|cp| cp.attr_courier_way_id.present?}
              validate :unit_available, if: proc{|cp| cp.courier_unit_id.present? && cp.courier_unit_id_changed?}
    
                before_destroy :delete_tracks

                private
                
                def unit_available                  
                  errors.add(:courier_unit_id, "does not exist!") if CourierUnit.joins(courier_way: :courier).select("1 AS one").where(id: courier_unit_id).where(["couriers.status = ? AND couriers.id = ? AND courier_ways.id = ?", "External", attr_courier_id, attr_courier_way_id]).blank?
                end
              
                def via_available
                  errors.add(:attr_courier_way_id, "does not exist!") if CourierWay.joins(:courier).select("1 AS one").where(id: attr_courier_way_id).where(["couriers.status = ? AND couriers.id = ?", "External", attr_courier_id]).blank?
                end
            
                def courier_available
                  errors.add(:attr_courier_id, "does not exist!") if Courier.select("1 AS one").where(status: "External").find(attr_courier_id).blank?
                end
          
                def delete_tracks
                  audits.destroy_all
                end
  
                def city_available
                  errors.add(:city_id, "does not exist!") if City.select("1 AS one").where(id: city_id).blank?
                end
      
                def price_type_available
                  CourierPrice::PRICE_TYPES.select{ |x| x[1] == price_type }.first.first
                rescue
                  errors.add(:price_type, "does not exist!")
                end
              end
