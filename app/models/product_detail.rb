class ProductDetail < ActiveRecord::Base
  belongs_to :size
  belongs_to :price_code
  belongs_to :product
  
  has_many :price_lists, dependent: :destroy
  #  has_many :purchase_order_details
  
  validates :barcode, uniqueness: {scope: :price_code_id} 

  accepts_nested_attributes_for :price_lists, reject_if: proc {|attributes| attributes[:price].blank?}

  before_create :create_barcode
  
  def active_price
    price_lists = self.price_lists.select(:id, :price, :effective_date).order("id DESC")
    if price_lists.size == 1
      return price_lists.first
    else
      price_lists.each do |price_list|
        if Date.today >= price_list.effective_date
          return price_list
        end
      end
    end
  end

  private
      
            
            
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
