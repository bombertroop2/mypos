class PriceList < ActiveRecord::Base
  belongs_to :product_detail
  
  validates :price, numericality: true, if: proc { |price_list| price_list.price.present? }
    validates :price, numericality: {greater_than_or_equal_to: 1}, if: proc { |price_list| price_list.price.is_a?(Numeric) }
      
    end
