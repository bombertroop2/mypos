class CourierPrice < ApplicationRecord
  attr_accessor :attr_add_price_from_menu_courier_price
	audited associated_with: :courier, on: [:create, :update]

  belongs_to :courier
  belongs_to :city
  

  PRICE_TYPES = [
    ["Regular", "Regular"],
    ["Express", "Express"]
  ]
  
  validates :city_id, :effective_date, :price_type, :price, presence: true
  validates :courier_id, presence: true, if: proc{|cp| cp.attr_add_price_from_menu_courier_price}
    validate :city_available, if: proc{|cp| cp.city_id.present? && cp.city_id_changed?}
      validates :effective_date, date: {after_or_equal_to: Proc.new { Date.current }, message: 'must be after or equal to today' }, if: proc {|cp| cp.effective_date.present? && cp.effective_date_changed?}
        validate :price_type_available, if: proc {|cp| cp.price_type.present? && cp.price_type_changed?}
          validates :price, numericality: {greater_than_or_equal_to: 1}, if: proc { |cp| cp.price.present? && cp.price_changed? && cp.price.is_a?(Numeric) }
            validate :courier_available, if: proc{|cp| cp.courier_id.present? && cp.courier_id_changed? && cp.attr_add_price_from_menu_courier_price}
    
              before_destroy :delete_tracks

              private
            
              def courier_available
                errors.add(:courier_id, "does not exist!") if Courier.select("1 AS one").where(status: "External").find(courier_id).blank?
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
