class SaleProduct < ApplicationRecord
  attr_accessor :sales_promotion_girl_id, :event_type, :effective_price, :attr_effective_cost,
    :first_plus_discount, :second_plus_discount, :cash_discount, :attr_returned_sale_id,
    :attr_returning_sale, :attr_gift_event_discount_amount, :attr_member_discount, :attr_product_spg_name
  
  belongs_to :sale
  belongs_to :product_barcode
  belongs_to :free_product, class_name: "StockDetail", foreign_key: :free_product_id
  belongs_to :price_list
  belongs_to :event
  belongs_to :returned_product, class_name: "SaleProduct", foreign_key: :returned_product_id
  belongs_to :cost_list

  # hapus event_id apabila event gift, cukup di parent Sale
  before_validation :add_quantity, :update_total, :update_gross_profit
  before_validation :remove_event_id, if: proc{|sp| sp.event_type.eql?("Gift")}

    validates :quantity, :cost_list_id, :price_list_id, presence: true
    validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |sp| sp.quantity.present? }
      validates :quantity, numericality: {less_than_or_equal_to: :stock_quantity, only_integer: true}, if: proc { |sp| sp.quantity.present? }
        validates :free_product_id, presence: true, if: proc{|sp| sp.event_id.present? && sp.event_type.eql?("Buy 1 Get 1 Free")}
          validates :total, numericality: {greater_than: 0}
          validate :returned_product_exist, if: proc {|sp| sp.attr_returning_sale}

            after_create :update_stock
        
            private
          
            def returned_product_exist
              returned_product = SaleProduct.
                joins(:sale).
                where(id: returned_product_id, :"sales.id" => attr_returned_sale_id).
                select("1 AS one").
                first
              errors.add(:returned_product_id, "doesn't exist") if returned_product.blank?
            end
          
            def add_quantity
              self.quantity = 1
            end
        
            def remove_event_id
              self.event_id = nil
            end
        
            def update_total
              if event_id.blank? || (event_id.present? && (event_type.eql?("Buy 1 Get 1 Free") || event_type.eql?("Special Price") || event_type.eql?("Gift")))
                total_before_member_discount = quantity * effective_price.to_f
                total_after_member_discount = total_before_member_discount - total_before_member_discount * (attr_member_discount.to_f / 100)
                self.total = total_after_member_discount
              elsif event_id.present? && event_type.eql?("Discount(%)")
                if first_plus_discount.present? && second_plus_discount.present?
                  first_discounted_subtotal = effective_price.to_f * quantity - effective_price.to_f * quantity * first_plus_discount.to_f / 100
                  second_discounted_subtotal = first_discounted_subtotal - first_discounted_subtotal * second_plus_discount.to_f / 100
                  total_after_member_discount = second_discounted_subtotal - second_discounted_subtotal * (attr_member_discount.to_f / 100)
                  self.total = total_after_member_discount
                elsif first_plus_discount.present?
                  total_before_member_discount = effective_price.to_f * quantity - effective_price.to_f * quantity * first_plus_discount.to_f / 100
                  total_after_member_discount = total_before_member_discount - total_before_member_discount * (attr_member_discount.to_f / 100)
                  self.total = total_after_member_discount
                end
              elsif event_id.present? && event_type.eql?("Discount(Rp)")
                total_before_member_discount = effective_price.to_f * quantity - cash_discount.to_f
                total_after_member_discount = total_before_member_discount - total_before_member_discount * (attr_member_discount.to_f / 100)
                self.total = total_after_member_discount
              end
            end

            def update_gross_profit
              self.gross_profit = if event_id.present? && event_type.eql?("Gift")
                if attr_gift_event_discount_amount.present?
                  total_before_gift_discount = quantity * effective_price.to_f
                  total_after_gift_discount = total_before_gift_discount - attr_gift_event_discount_amount
                  total_after_member_discount = total_after_gift_discount - total_after_gift_discount * (attr_member_discount.to_f / 100)
                  total_after_member_discount - attr_effective_cost
                else
                  total - attr_effective_cost
                end
              else
                if attr_gift_event_discount_amount.present?
                  total_before_member_discount = if attr_member_discount.to_f > 0
                    (total * 100).to_f / (100 - attr_member_discount.to_f)
                  else
                    total
                  end
                  total_after_gift_discount = total_before_member_discount - attr_gift_event_discount_amount
                  total_after_member_discount = total_after_gift_discount - total_after_gift_discount * (attr_member_discount.to_f / 100)
                  total_after_member_discount - attr_effective_cost
                else
                  total - attr_effective_cost
                end
              end
            end
      
            def stock_quantity
              @sd = StockDetail.joins(:size, stock_product: [product: [product_colors: :product_barcodes], stock: [warehouse: :sales_promotion_girls]]).
                where(:"sales_promotion_girls.id" => sales_promotion_girl_id, :"product_barcodes.id" => product_barcode_id, :"warehouses.is_active" => true).
                where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
                select(:id, :quantity, :booked_quantity, :barcode).first
              @barcode = @sd.barcode
              @sd.quantity.to_i - @sd.booked_quantity.to_i
            end
        
            def update_stock
              raise_error = false
              @sd.with_lock do
                if @sd.quantity.to_i - @sd.booked_quantity.to_i >= quantity
                  @sd.quantity -= quantity
                  @sd.save
                else
                  raise_error = true
                end
              end          
              if raise_error
                raise "Sorry, product #{@barcode} is temporarily out of stock"
              else
                if event_id.present? && event_type.eql?("Buy 1 Get 1 Free") && free_product_id.present?
                  free_product_stock = StockDetail.where(id: free_product_id).select(:id, :quantity, :booked_quantity).first
                  free_product_stock.with_lock do
                    if free_product_stock.quantity.to_i - free_product_stock.booked_quantity.to_i >= quantity
                      free_product_stock.quantity -= quantity
                      free_product_stock.save
                    else
                      raise_error = true
                    end
                  end            
                  raise "Sorry, free product from product #{@barcode} is temporarily out of stock" if raise_error
                end
              end
            end
          end
