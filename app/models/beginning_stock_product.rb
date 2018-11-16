class BeginningStockProduct < ApplicationRecord
  belongs_to :product
    
  validates :product_id, :quantity, :import_date, :warehouse_id, :size_id, :color_id, presence: true
  validate :warehouse_available, :product_available, :color_available, :size_available, :product_barcode_available
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |bsp| bsp.quantity.present? }
    validates :import_date, date: {before_or_equal_to: Proc.new { Date.current }, message: 'must be before or equal to today' }, if: proc {|bsp| bsp.import_date_changed?}
  
      after_create :save_stock, :create_listing_stock, :create_stock_movement

      private
      
      def create_stock_movement                  
        stock_movement = StockMovement.select(:id).where(year: import_date.year).first
        stock_movement = StockMovement.new year: import_date.year if stock_movement.blank?
        if stock_movement.new_record?                    
          stock_movement_month = stock_movement.stock_movement_months.build month: import_date.month
          stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
          stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
            size_id: size_id, beginning_stock: 0, ending_stock: quantity
          stock_movement_product_detail.stock_movement_transactions.build beginning_stock: quantity, transaction_date: import_date
          stock_movement.save
        else
          stock_movement_month = stock_movement.stock_movement_months.select(:id).where(month: import_date.month).first
          stock_movement_month = stock_movement.stock_movement_months.build month: import_date.month if stock_movement_month.blank?
          if stock_movement_month.new_record?                      
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
            stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
            stock_movement_product_detail = stock_movement_product.
              stock_movement_product_details.build color_id: color_id,
              size_id: size_id, beginning_stock: 0, ending_stock: quantity
            stock_movement_product_detail.stock_movement_transactions.build beginning_stock: quantity, transaction_date: import_date
            stock_movement_month.save
          else
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select(:id).where(warehouse_id: warehouse_id).first
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id if stock_movement_warehouse.blank?
            if stock_movement_warehouse.new_record?                        
              stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
              stock_movement_product_detail = stock_movement_product.
                stock_movement_product_details.build color_id: color_id,
                size_id: size_id, beginning_stock: 0, ending_stock: quantity
              stock_movement_product_detail.stock_movement_transactions.build beginning_stock: quantity, transaction_date: import_date
              stock_movement_warehouse.save
            else
              stock_movement_product = stock_movement_warehouse.stock_movement_products.select(:id).where(product_id: product_id).first
              stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id if stock_movement_product.blank?
              if stock_movement_product.new_record?                          
                stock_movement_product_detail = stock_movement_product.
                  stock_movement_product_details.build color_id: color_id,
                  size_id: size_id, beginning_stock: 0, ending_stock: quantity
                stock_movement_product_detail.stock_movement_transactions.build beginning_stock: quantity, transaction_date: import_date
                stock_movement_product.save
              else
                stock_movement_product_detail = stock_movement_product.
                  stock_movement_product_details.build color_id: color_id,
                  size_id: size_id, beginning_stock: 0, ending_stock: quantity
                stock_movement_product_detail.stock_movement_transactions.build beginning_stock: quantity, transaction_date: import_date
                stock_movement_product_detail.save
              end
            end
          end
        end
      end
      
      def create_listing_stock
        listing_stock = ListingStock.select(:id).where(warehouse_id: warehouse_id, product_id: product_id).first
        listing_stock = ListingStock.new warehouse_id: warehouse_id, product_id: product_id if listing_stock.blank?
        if listing_stock.new_record?                    
          listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id
          listing_stock_product_detail.listing_stock_transactions.build transaction_date: import_date, transaction_type: "BS", transactionable_id: self.id, transactionable_type: self.class.name, quantity: quantity
          listing_stock.save
        else
          listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id
          listing_stock_product_detail.listing_stock_transactions.build transaction_date: import_date, transaction_type: "BS", transactionable_id: self.id, transactionable_type: self.class.name, quantity: quantity
          listing_stock_product_detail.save
        end
      end
      
      def save_stock
        stock = Stock.select(:id).where(warehouse_id: warehouse_id).first
        if stock.blank?
          stock = Stock.new warehouse_id: warehouse_id
          stock_product = stock.stock_products.build product_id: product_id
          stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: quantity
          stock.save
        else
          stock_product = stock.stock_products.select(:id).where(product_id: product_id).first
          if stock_product.blank?
            stock_product = stock.stock_products.build product_id: product_id
            stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: quantity
            stock_product.save
          else
            stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: quantity
            stock_detail.save
          end
        end
      end
  
      def warehouse_available
        if warehouse_id.present?
          errors.add(:warehouse_id, "doesn't exist") if Warehouse.select("1 AS one").where(id: warehouse_id).not_in_transit.not_direct_sales.blank?
        end
      end  
      
      def product_available
        if product_id.present?
          errors.add(:product_id, "doesn't exist") if (@prdct = Product.select(:id, :size_group_id).where(id: product_id).first).blank?
        end
      end
      
      def color_available
        if color_id.present?
          errors.add(:color_id, "doesn't exist") if (@clr = Color.select(:id).joins(:product_colors).where(id: color_id, :"product_colors.product_id" => @prdct.id).first).blank?
        end
      end
      
      def size_available
        if size_id.present?
          errors.add(:size_id, "doesn't exist") if (@sz = Size.select(:id).joins(:size_group).where(id: size_id, :"size_groups.id" => @prdct.size_group_id).first).blank?
        end
      end
      
      def product_barcode_available
        if @clr.present? && @sz.present?
          errors.add(:base, "Color or size doesn't exist") if ProductBarcode.select("1 AS one").joins(:product_color).where(size_id: @sz.id).where(["product_colors.product_id = ? AND product_colors.color_id = ?", @prdct.id, @clr.id]).blank?
        end
      end
    end
