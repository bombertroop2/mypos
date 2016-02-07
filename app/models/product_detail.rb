class ProductDetail < ActiveRecord::Base
  belongs_to :size
  belongs_to :color
  belongs_to :product_price_code
  
  has_many :product_detail_histories, dependent: :destroy
  #  has_many :purchase_order_details
  
  validates :barcode, uniqueness: true    
  validates :price, numericality: true, if: proc { |prdet| prdet.price.present? }        
    validates :price, numericality: {greater_than_or_equal_to: 1}, if: proc { |prdet| prdet.price.is_a?(Numeric) }

      accepts_nested_attributes_for :product_detail_histories

      before_validation :delete_record
      before_create :create_barcode
      before_save :create_history

      private
      
      def delete_record
        unless new_record?
          destroy if price.blank?
        end
      end
            
            
      def create_barcode
        last_detail = ProductDetail.last
        self.barcode = "000000000000001" if last_detail.nil?
        self.barcode = last_detail.barcode.succ unless last_detail.nil?
      end
        

      def create_history
        if !price_was.eql?(price)
          self.attributes = self.attributes.merge(product_detail_histories_attributes: {"0" => {
                price: self.price,
                product_detail_id: self.id
              }})
        end
      end
    end
