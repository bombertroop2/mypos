class ProductDetail < ApplicationRecord
  attr_accessor :user_is_adding_new_product, :size_group_id

  belongs_to :size
  belongs_to :price_code
  belongs_to :product
  
  has_many :price_lists, dependent: :destroy
  #  has_many :purchase_order_details
  
  validates :barcode, uniqueness: {scope: :price_code_id} 
  validates :size_id, :price_code_id, presence: true
  validates :product_id, presence: true, unless: proc{|product_detail| product_detail.user_is_adding_new_product}
    validate :size_available, :price_code_available, on: :create

    accepts_nested_attributes_for :price_lists#, reject_if: proc {|attributes| attributes[:price].blank?}

    before_create :create_barcode
  
    def active_price
      price_lists = self.price_lists.select(:id, :price, :effective_date).order("effective_date DESC")
      price_lists.each do |price_list|
        if Time.current.to_date >= price_list.effective_date
          return price_list
        end
      end
      return nil
    end
  
    def price_count
      price_lists.count(:id)
    end

    private      
    
    def size_available
      errors.add(:size_id, "does not exist!") if size_id.present? && Size.where("sizes.id = #{size_id} AND size_groups.id = #{size_group_id}").joins(:size_group).select("1 AS one").blank?
    end

    def price_code_available      
      errors.add(:price_code_id, "does not exist!") if price_code_id.present? && PriceCode.where(id: price_code_id).select("1 AS one").blank?
    end
            
    def create_barcode
      product_detail = ProductDetail.select{|pd| pd.size_id.eql?(size_id) and pd.product_id.eql?(product_id)}.first
      if product_detail
        self.barcode = product_detail.barcode
      else
        last_detail = ProductDetail.last
        self.barcode = "000000000000001" if last_detail.nil?
        self.barcode = last_detail.barcode.succ unless last_detail.nil?
      end
    end
        

  end
