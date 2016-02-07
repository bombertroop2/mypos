class ProductPriceCode < ActiveRecord::Base
  belongs_to :product
  belongs_to :price_code
  
  has_many :product_details, dependent: :destroy
  
  accepts_nested_attributes_for :product_details,
    reject_if: proc {|attributes| attributes[:price].blank? and attributes[:id].blank? }
  
  attr_accessor :total_size
  
  validate :validate_product_details
  
  def validate_product_details
    errors.add(:base, "You should add at least #{total_size} prices per price code") if product_details.size < total_size.to_i
  end
end
