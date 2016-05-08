class DirectPurchase < ActiveRecord::Base
  belongs_to :vendor
  belongs_to :warehouse
  
  has_one :received_purchase_order, dependent: :destroy
  has_many :direct_purchase_products, dependent: :destroy
  
  accepts_nested_attributes_for :direct_purchase_products
  accepts_nested_attributes_for :received_purchase_order
  
  validates :vendor_id, :warehouse_id, :receiving_date, presence: true
  validates :first_discount, numericality: {greater_than: 0, less_than_or_equal_to: 100}, if: proc {|dp| dp.first_discount.present?}
    validate :prevent_adding_second_discount_if_first_discount_is_100, if: proc {|dp| dp.second_discount.present?}
      validates :first_discount, presence: true, if: proc {|dp| dp.second_discount.present?}
        validate :prevent_combining_discount, if: proc {|dp| dp.first_discount.present? && dp.price_discount.present?}
          validate :prevent_adding_second_discount_if_total_discount_greater_than_100, if: proc {|dp| dp.second_discount.present? && !dp.is_additional_disc_from_net}
            validates :second_discount, numericality: {greater_than: 0, less_than_or_equal_to: 100}, if: proc {|dp| dp.second_discount.present?}
              validates :price_discount, numericality: {greater_than: 0}, if: proc { |dp| dp.price_discount.present? && dp.price_discount.is_a?(Numeric) }
                validate :price_discount_must_be_less_than_or_equal_to_total_receiving, if: proc { |dp| dp.price_discount.present? && dp.price_discount.is_a?(Numeric) && dp.receiving_date.present? }
                  validate :should_has_products  
                  validates :receiving_date, date: {before_or_equal_to: Proc.new { Date.today }, message: 'must be before or equal to today' }, if: proc {|dp| dp.receiving_date.present?}
  
                  before_create :set_vat_and_entrepreneur_status, :set_nil_to_is_additional_disc_from_net
  
                  private
                
                  def should_has_products
                    errors.add(:base, "Please select at least one product!") if direct_purchase_products.blank?
                  end
                
                  def price_discount_must_be_less_than_or_equal_to_total_receiving
                    total_receiving_quantity_per_product = 0
                    total_receiving_value = 0
                    direct_purchase_products.each do |direct_purchase_product|
                      total_receiving_quantity_per_product = direct_purchase_product.direct_purchase_details.map(&:quantity).sum
                      total_receiving_value += direct_purchase_product.active_cost(receiving_date).cost * total_receiving_quantity_per_product
                    end
                    errors.add(:price_discount, "must be less than or equal to total receiving value") if total_receiving_value < price_discount
                  end
              
                  def set_nil_to_is_additional_disc_from_net                                        
                    self.is_additional_disc_from_net = nil if second_discount.blank?
                  end
          
                  def prevent_adding_second_discount_if_total_discount_greater_than_100
                    errors.add(:second_discount, "can't be added, because total discount (1st discount + 2nd discount) is greater than 100%") if (first_discount + second_discount) > 100 && second_discount <= 100
                  end
          
                  def prevent_combining_discount
                    errors.add(:first_discount, "can't be combined with price discount")
                    errors.add(:price_discount, "can't be combined with double discount")
                  end
      
                  def prevent_adding_second_discount_if_first_discount_is_100
                    errors.add(:second_discount, "can't be added, because first discount is already 100%") if first_discount == 100
                  end
  
                  def set_vat_and_entrepreneur_status
                    self.vat_type = vendor.value_added_tax
                    self.is_taxable_entrepreneur = vendor.is_taxable_entrepreneur
                    return true
                  end
                end