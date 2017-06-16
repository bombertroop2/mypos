class OrderBookingProductItem < ApplicationRecord
  attr_accessor :product_id, :new_product, :disable_validation, :old_available_quantity,
    :shipping, :cancel_shipment

  audited associated_with: :order_booking_product, on: [:create, :update], except: :available_quantity

  belongs_to :order_booking_product
  belongs_to :size
  belongs_to :color

  validates :quantity, presence: true, unless: proc{|obpi| obpi.disable_validation}
    validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |dpd| dpd.quantity.present? }
      validate :item_available, unless: proc{|obpi| obpi.disable_validation}
        validate :quantity_available, if: proc{|obpi| obpi.quantity.present? && obpi.quantity.is_a?(Numeric)}
    
          before_save :update_booked_quantity, :update_total_quantity
          before_destroy :delete_tracks
          after_destroy :update_booked_quantity
          after_update :update_stock_and_booked_quantity, if: proc{|spi| spi.shipping || spi.cancel_shipment}
      
            def available_for_booking_quantity=(value)
              @available_for_booking_quantity = value
            end
      
            def available_for_booking_quantity       
              unless new_record?
                unless @stock_item.present?
                  product_id = order_booking_product.product_id
                  stock_item = StockDetail.joins(stock_product: :stock).select(:id, :quantity, :booked_quantity).
                    where(size_id: size_id, color_id: color_id).
                    where("stock_products.product_id = #{product_id} AND stocks.warehouse_id = #{origin_warehouse_id}").first
                  self.available_for_booking_quantity = stock_item.quantity - (stock_item.booked_quantity - quantity_was)
                else
                  self.available_for_booking_quantity = @stock_item.quantity - (@stock_item.booked_quantity - quantity_was)
                end
              end
              @available_for_booking_quantity
            end
      

            private
            
            def delete_tracks
              audits.destroy_all
            end
            
            def update_stock_and_booked_quantity
              stock_item = StockDetail.joins(stock_product: :stock).select(:id, :booked_quantity, :quantity).
                where(size_id: size_id, color_id: color_id).where("stock_products.product_id = #{order_booking_product.product_id} AND stocks.warehouse_id = #{origin_warehouse_id}").first
              if shipping
                booked_quantity = stock_item.booked_quantity - quantity
                stock_item.update_attribute :booked_quantity, booked_quantity
                last_quantity = stock_item.quantity - available_quantity
                stock_item.update_attribute :quantity, last_quantity
              else
                booked_quantity = stock_item.booked_quantity + quantity
                stock_item.update_attribute :booked_quantity, booked_quantity
                last_quantity = stock_item.quantity + old_available_quantity
                stock_item.update_attribute :quantity, last_quantity
              end
            end
      
            def quantity_available
              if new_record?
                self.available_for_booking_quantity = available_quantity = @stock_item.quantity - @stock_item.booked_quantity
                errors.add(:quantity, "cannot be greater than #{available_quantity}") if quantity > available_quantity
              elsif quantity_changed? && persisted?
                @stock_item = StockDetail.joins(stock_product: :stock).select(:id, :quantity, :booked_quantity).
                  where(size_id: size_id, color_id: color_id).
                  where("stock_products.product_id = #{product_id} AND stocks.warehouse_id = #{origin_warehouse_id}").first
                available_quantity = @stock_item.quantity - (@stock_item.booked_quantity - quantity_was)
                errors.add(:quantity, "cannot be greater than #{available_quantity}") if quantity > available_quantity
              end
            end

            def item_available
              if new_record? || ((size_id_changed? || color_id_changed?) && persisted?)
                @stock_item = StockDetail.joins(stock_product: :stock).select(:id, :quantity, :booked_quantity).
                  where(size_id: size_id, color_id: color_id).
                  where("stock_products.product_id = #{product_id} AND stocks.warehouse_id = #{origin_warehouse_id}").first
                errors.add(:base, "Not able to order selected items") if @stock_item.blank?
              end
            end
    
            def update_booked_quantity
              unless destroyed?
                if new_record?
                  total_booked_quantity = @stock_item.booked_quantity + quantity
                  @stock_item.update_attribute :booked_quantity, total_booked_quantity
                elsif quantity_changed? && persisted?
                  total_booked_quantity = (@stock_item.booked_quantity - quantity_was) + quantity
                  @stock_item.update_attribute :booked_quantity, total_booked_quantity
                end
              else
                stock_item = StockDetail.joins(stock_product: :stock).select(:id, :booked_quantity).
                  where(size_id: size_id, color_id: color_id).where("stock_products.product_id = #{order_booking_product.product_id} AND stocks.warehouse_id = #{origin_warehouse_id}").first
                booked_quantity = stock_item.booked_quantity - quantity
                stock_item.update_attribute :booked_quantity, booked_quantity
              end
            end
      
            def update_total_quantity
              unless new_product
                if new_record?
                  last_obp_quantity = order_booking_product.quantity
                  new_obp_quantity = last_obp_quantity + quantity
                  order_booking_product.without_auditing do
                    order_booking_product.update_attribute :quantity, new_obp_quantity
                  end

                  order_booking = order_booking_product.order_booking
                  last_ob_quantity = order_booking.quantity
                  new_ob_quantity = last_ob_quantity + quantity
                  order_booking.without_auditing do
                    order_booking.update_attribute :quantity, new_ob_quantity
                  end
                elsif quantity_changed? && persisted?
                  last_obp_quantity = order_booking_product.quantity
                  new_obp_quantity = (last_obp_quantity - quantity_was) + quantity
                  order_booking_product.without_auditing do
                    order_booking_product.update_attribute :quantity, new_obp_quantity
                  end

                  order_booking = order_booking_product.order_booking
                  last_ob_quantity = order_booking.quantity
                  new_ob_quantity = (last_ob_quantity - quantity_was) + quantity
                  order_booking.without_auditing do
                    order_booking.update_attribute :quantity, new_ob_quantity
                  end
                end
              end
            end
      
          end
