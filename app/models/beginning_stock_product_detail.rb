class BeginningStockProductDetail < ApplicationRecord
  belongs_to :beginning_stock_product
  belongs_to :color
  belongs_to :size
  
  after_create :create_listing_stock, :create_stock_movement
  
  private
  
  def create_listing_stock
    beginning_stock_product = BeginningStockProduct.select(:beginning_stock_month_id, :product_id).where(id: beginning_stock_product_id).first
    beginning_stock_month = BeginningStockMonth.select(:beginning_stock_id, :month).where(id: beginning_stock_product.beginning_stock_month_id).first
    beginning_stock = BeginningStock.select(:warehouse_id, :year).where(id: beginning_stock_month.beginning_stock_id).first

    listing_stock = ListingStock.select(:id).where(warehouse_id: beginning_stock.warehouse_id, product_id: beginning_stock_product.product_id).first
    listing_stock = ListingStock.new warehouse_id: beginning_stock.warehouse_id, product_id: beginning_stock_product.product_id if listing_stock.blank?
    if listing_stock.new_record?                    
      listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id
      listing_stock_product_detail.listing_stock_transactions.build transaction_date: "1/#{beginning_stock_month.month}/#{beginning_stock.year}".to_date, transaction_type: "BS", transactionable_id: self.id, transactionable_type: self.class.name, quantity: quantity
      listing_stock.save
    else
      listing_stock_product_detail = listing_stock.listing_stock_product_details.where(color_id: color_id, size_id: size_id).select(:id).first
      listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id if listing_stock_product_detail.blank?
      if listing_stock_product_detail.new_record?
        listing_stock_product_detail.listing_stock_transactions.build transaction_date: "1/#{beginning_stock_month.month}/#{beginning_stock.year}".to_date, transaction_type: "BS", transactionable_id: self.id, transactionable_type: self.class.name, quantity: quantity
        listing_stock_product_detail.save
      else
        listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.build transaction_date: "1/#{beginning_stock_month.month}/#{beginning_stock.year}".to_date, transaction_type: "BS", transactionable_id: self.id, transactionable_type: self.class.name, quantity: quantity
        listing_stock_transaction.save
      end
    end
  end
  
  def create_stock_movement                  
    beginning_stock_product = BeginningStockProduct.select(:beginning_stock_month_id, :product_id).where(id: beginning_stock_product_id).first
    beginning_stock_month = BeginningStockMonth.select(:beginning_stock_id, :month).where(id: beginning_stock_product.beginning_stock_month_id).first
    beginning_stock = BeginningStock.select(:warehouse_id, :year).where(id: beginning_stock_month.beginning_stock_id).first

    stock_movement = StockMovement.select(:id).where(year: beginning_stock.year).first
    stock_movement = StockMovement.new year: beginning_stock.year if stock_movement.blank?
    if stock_movement.new_record?                    
      stock_movement_month = stock_movement.stock_movement_months.build month: beginning_stock_month.month
      stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: beginning_stock.warehouse_id
      stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: beginning_stock_product.product_id
      stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
        size_id: size_id, beginning_stock: 0, ending_stock: (0 + quantity)      
      stock_movement_product_detail.stock_movement_transactions.build beginning_stock: quantity, transaction_date: "1/#{beginning_stock_month.month}/#{beginning_stock.year}".to_date
      stock_movement.save
    else
      stock_movement_month = stock_movement.stock_movement_months.select(:id).where(month: beginning_stock_month.month).first
      stock_movement_month = stock_movement.stock_movement_months.build month: beginning_stock_month.month if stock_movement_month.blank?
      if stock_movement_month.new_record?                      
        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: beginning_stock.warehouse_id
        stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: beginning_stock_product.product_id
        stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
          size_id: size_id, beginning_stock: 0, ending_stock: (0 + quantity)
        stock_movement_product_detail.stock_movement_transactions.build beginning_stock: quantity, transaction_date: "1/#{beginning_stock_month.month}/#{beginning_stock.year}".to_date
        stock_movement_month.save
      else
        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select(:id).where(warehouse_id: beginning_stock.warehouse_id).first
        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: beginning_stock.warehouse_id if stock_movement_warehouse.blank?
        if stock_movement_warehouse.new_record?                        
          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: beginning_stock_product.product_id
          stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
            size_id: size_id, beginning_stock: 0, ending_stock: (0 + quantity)
          stock_movement_product_detail.stock_movement_transactions.build beginning_stock: quantity, transaction_date: "1/#{beginning_stock_month.month}/#{beginning_stock.year}".to_date
          stock_movement_warehouse.save
        else
          stock_movement_product = stock_movement_warehouse.stock_movement_products.select(:id).where(product_id: beginning_stock_product.product_id).first
          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: beginning_stock_product.product_id if stock_movement_product.blank?
          if stock_movement_product.new_record?                          
            stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
              size_id: size_id, beginning_stock: 0, ending_stock: (0 + quantity)
            stock_movement_product_detail.stock_movement_transactions.build beginning_stock: quantity, transaction_date: "1/#{beginning_stock_month.month}/#{beginning_stock.year}".to_date
            stock_movement_product.save
          else
            stock_movement_product_detail = stock_movement_product.stock_movement_product_details.select(:id, :ending_stock).
              where(color_id: color_id, size_id: size_id).first
            if stock_movement_product_detail.blank?
              stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                size_id: size_id, beginning_stock: 0, ending_stock: (0 + quantity)
              stock_movement_product_detail.stock_movement_transactions.build beginning_stock: quantity, transaction_date: "1/#{beginning_stock_month.month}/#{beginning_stock.year}".to_date
              stock_movement_product_detail.save
            else
              stock_movement_product_detail.with_lock do
                stock_movement_product_detail.ending_stock += quantity
                stock_movement_product_detail.stock_movement_transactions.build beginning_stock: quantity, transaction_date: "1/#{beginning_stock_month.month}/#{beginning_stock.year}".to_date
                stock_movement_product_detail.save
              end
            end
          end
        end
      end
    end
  end
end
