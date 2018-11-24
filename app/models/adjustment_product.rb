class AdjustmentProduct < ApplicationRecord
  attr_accessor :attr_product_code, :attr_brand_name, :attr_warehouse_id
  belongs_to :adjustment
  belongs_to :product
  has_many :adjustment_product_details, dependent: :destroy
  
  accepts_nested_attributes_for :adjustment_product_details, reject_if: proc { |attributes| attributes[:quantity].blank? }
  
  validate :check_min_product_quantity
  validate :article_sex_not_valid, if: proc{|ap| ap.product_id.present? && attr_warehouse_id.present?}

    private
    
    def article_sex_not_valid
      product = Product.joins(:goods_type).
        where(id: product_id).
        select(:sex, "common_fields.name AS goods_type_name").first
      if !product.sex.downcase.eql?("unisex")
        dest_warehouse = Warehouse.select(:code, :counter_type).find(attr_warehouse_id)
        if dest_warehouse.counter_type.blank? || dest_warehouse.counter_type.eql?("Bazar")
        elsif dest_warehouse.counter_type.eql?("Bags")
          if !product.goods_type_name.strip.downcase.eql?("bag") && !product.goods_type_name.strip.downcase.eql?("bags")
            errors.add(:base, "Article #{attr_product_code} is not allowed for warehouse #{dest_warehouse.code}")
          end
        elsif !dest_warehouse.counter_type.downcase.eql?(product.sex.downcase)
          errors.add(:base, "Article #{attr_product_code} is not allowed for warehouse #{dest_warehouse.code}")
        end
      end
    end
  
    def check_min_product_quantity
      errors.add(:base, "Adjustment must have at least one quantity per product") if adjustment_product_details.blank?
    end
  end
