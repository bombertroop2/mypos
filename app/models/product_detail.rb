class ProductDetail < ActiveRecord::Base
  belongs_to :product
  belongs_to :size
  belongs_to :color
  belongs_to :price_code
  
  has_many :product_detail_histories, dependent: :destroy
  #  has_many :purchase_order_details
  
  validates :size_id, uniqueness: {scope: [:color_id, :product_id, :price_code_id]}, if: Proc.new { |prdet| prdet.size_id.present? }
    validates :barcode, uniqueness: true
    validates :cost, numericality: true, if: Proc.new { |prdet| prdet.cost.present? }
      validates :price, numericality: true, if: Proc.new { |prdet| prdet.price.present? }
        validates :cost, numericality: {greater_than: 0}, if: Proc.new { |prdet| prdet.cost.is_a?(Numeric) }
          validates :price, numericality: {greater_than: 0}, if: Proc.new { |prdet| prdet.price.is_a?(Numeric) }

            accepts_nested_attributes_for :product_detail_histories

            before_create :create_barcode
            before_save :create_history
            before_validation :remove_zero_value_record, if: Proc.new {|prdet| !prdet.new_record?}

              private
            
              def remove_zero_value_record
                self.destroy if (cost == 0 or cost.nil?) and (price == 0 or price.nil?)
              end
            
              def create_barcode          
                last_detail = ProductDetail.last
                self.barcode = "000000000000001" if last_detail.nil?
                self.barcode = last_detail.barcode.succ unless last_detail.nil?
              end
        

              def create_history
                if (!cost_was.eql?(cost) || !price_was.eql?(price))
                  self.attributes = self.attributes.merge(product_detail_histories_attributes: {"0" => {
                        cost: self.cost,
                        price: self.price,
                        product_detail_id: self.id
                      }})
                end
              end
            end
