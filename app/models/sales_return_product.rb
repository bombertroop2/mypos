class SalesReturnProduct < ApplicationRecord
  attr_accessor :attr_product_detail, :attr_sale_id, :attr_warehouse_id
  
  belongs_to :sale_product
  belongs_to :sales_return
  
  REASONS = [
    ["Damaged", "Damaged"],
    ["Not Suitable", "Not Suitable"]
  ]
  
  validate :returned_product_exist

  before_create :get_stock_detail  
  after_create :create_listing_stock, :create_stock_movement, :update_stock
  
  private
  
  def returned_product_exist
    returned_product = SaleProduct.joins("LEFT JOIN events on events.id = sale_products.event_id").
      where(id: sale_product_id, sale_id: attr_sale_id).
      select("events.event_type AS returned_product_event_type").first
    if returned_product.blank? || (returned_product.present? && (returned_product.returned_product_event_type.eql?("Buy 1 Get 1 Free") || returned_product.returned_product_event_type.eql?("Gift")))
      errors.add(:sale_product_id, "does not exist!")
    end
  end
  
  def get_stock_detail
    product_barcode_id = SaleProduct.select(:product_barcode_id).where(id: sale_product_id).first.product_barcode_id
    @sd = StockDetail.joins(stock_product: [:stock, product: [product_colors: :product_barcodes]]).
      where(:"product_barcodes.id" => product_barcode_id).
      where(["stocks.warehouse_id = ?", attr_warehouse_id]).
      where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
      select(:id, :quantity, "stock_products.product_id", "stock_details.color_id", "stock_details.size_id").first
  end
  
  def update_stock    
    @sd.with_lock do
      @sd.quantity += 1
      @sd.save
    end          
  end
  
  def create_listing_stock
    # listing stock untuk item yang diretur
    @sales_return = SalesReturn.select(:id, :created_at, :document_number).where(id: sales_return_id).first
    listing_stock = ListingStock.select(:id).where(warehouse_id: attr_warehouse_id, product_id: @sd.product_id).first
    listing_stock = ListingStock.new warehouse_id: attr_warehouse_id, product_id: @sd.product_id if listing_stock.blank?
    if listing_stock.new_record?                    
      listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: @sd.color_id, size_id: @sd.size_id
      listing_stock_product_detail.listing_stock_transactions.build transaction_date: @sales_return.created_at.to_date, transaction_number: @sales_return.document_number, transaction_type: "RET", transactionable_id: @sales_return.id, transactionable_type: @sales_return.class.name, quantity: 1
      listing_stock.save
    else
      listing_stock_product_detail = listing_stock.listing_stock_product_details.where(color_id: @sd.color_id, size_id: @sd.size_id).select(:id).first
      listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: @sd.color_id, size_id: @sd.size_id if listing_stock_product_detail.blank?
      if listing_stock_product_detail.new_record?
        listing_stock_product_detail.listing_stock_transactions.build transaction_date: @sales_return.created_at.to_date, transaction_number: @sales_return.document_number, transaction_type: "RET", transactionable_id: @sales_return.id, transactionable_type: @sales_return.class.name, quantity: 1
        listing_stock_product_detail.save
      else
        listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.where(transaction_date: @sales_return.created_at.to_date, transaction_number: @sales_return.document_number, transaction_type: "RET", transactionable_id: @sales_return.id, transactionable_type: @sales_return.class.name).select(:id, :quantity).first
        if listing_stock_transaction.present?
          listing_stock_transaction.with_lock do
            listing_stock_transaction.quantity += 1
            listing_stock_transaction.save
          end
        else
          listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.build transaction_date: @sales_return.created_at.to_date, transaction_number: @sales_return.document_number, transaction_type: "RET", transactionable_id: @sales_return.id, transactionable_type: @sales_return.class.name, quantity: 1
          listing_stock_transaction.save
        end
      end
    end
  end 
  
  
  def create_stock_movement
    stock_movement = StockMovement.select(:id).where(year: @sales_return.created_at.year).first
    stock_movement = StockMovement.new year: @sales_return.created_at.year if stock_movement.blank?
    if stock_movement.new_record?                    
      beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", attr_warehouse_id, @sd.product_id, @sd.color_id, @sd.size_id, @sales_return.created_at.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
      beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", @sales_return.created_at.year, @sales_return.created_at.month, @sales_return.created_at.year, attr_warehouse_id, @sd.product_id, @sd.color_id, @sd.size_id]).first.quantity rescue nil if beginning_stock.nil?
      beginning_stock = 0 if beginning_stock.nil?                        
      stock_movement_month = stock_movement.stock_movement_months.build month: @sales_return.created_at.month
      stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: attr_warehouse_id
      stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: @sd.product_id
      stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: @sd.color_id,
        size_id: @sd.size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + 1)
      stock_movement_product_detail.stock_movement_transactions.build sales_return_quantity_received: 1, transaction_date: @sales_return.created_at.to_date
      stock_movement.save
    else
      stock_movement_month = stock_movement.stock_movement_months.select(:id).where(month: @sales_return.created_at.month).first
      stock_movement_month = stock_movement.stock_movement_months.build month: @sales_return.created_at.month if stock_movement_month.blank?
      if stock_movement_month.new_record?                      
        beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", attr_warehouse_id, @sd.product_id, @sd.color_id, @sd.size_id, @sales_return.created_at.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
        beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", @sales_return.created_at.year, @sales_return.created_at.month, @sales_return.created_at.year, attr_warehouse_id, @sd.product_id, @sd.color_id, @sd.size_id]).first.quantity rescue nil if beginning_stock.nil?
        beginning_stock = 0 if beginning_stock.nil?                        
        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: attr_warehouse_id
        stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: @sd.product_id
        stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: @sd.color_id,
          size_id: @sd.size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + 1)
        stock_movement_product_detail.stock_movement_transactions.build sales_return_quantity_received: 1, transaction_date: @sales_return.created_at.to_date
        stock_movement_month.save
      else
        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select(:id).where(warehouse_id: attr_warehouse_id).first
        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: attr_warehouse_id if stock_movement_warehouse.blank?
        if stock_movement_warehouse.new_record?                        
          beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", attr_warehouse_id, @sd.product_id, @sd.color_id, @sd.size_id, @sales_return.created_at.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
          beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", @sales_return.created_at.year, @sales_return.created_at.month, @sales_return.created_at.year, attr_warehouse_id, @sd.product_id, @sd.color_id, @sd.size_id]).first.quantity rescue nil if beginning_stock.nil?
          beginning_stock = 0 if beginning_stock.nil?                        
          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: @sd.product_id
          stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: @sd.color_id,
            size_id: @sd.size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + 1)
          stock_movement_product_detail.stock_movement_transactions.build sales_return_quantity_received: 1, transaction_date: @sales_return.created_at.to_date
          stock_movement_warehouse.save
        else
          stock_movement_product = stock_movement_warehouse.stock_movement_products.select(:id).where(product_id: @sd.product_id).first
          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: @sd.product_id if stock_movement_product.blank?
          if stock_movement_product.new_record?                          
            beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", attr_warehouse_id, @sd.product_id, @sd.color_id, @sd.size_id, @sales_return.created_at.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
            beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", @sales_return.created_at.year, @sales_return.created_at.month, @sales_return.created_at.year, attr_warehouse_id, @sd.product_id, @sd.color_id, @sd.size_id]).first.quantity rescue nil if beginning_stock.nil?
            beginning_stock = 0 if beginning_stock.nil?                        
            stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: @sd.color_id,
              size_id: @sd.size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + 1)
            stock_movement_product_detail.stock_movement_transactions.build sales_return_quantity_received: 1, transaction_date: @sales_return.created_at.to_date
            stock_movement_product.save
          else
            stock_movement_product_detail = stock_movement_product.stock_movement_product_details.select(:id, :ending_stock).
              where(color_id: @sd.color_id, size_id: @sd.size_id).first
            if stock_movement_product_detail.blank?
              beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", attr_warehouse_id, @sd.product_id, @sd.color_id, @sd.size_id, @sales_return.created_at.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
              beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", @sales_return.created_at.year, @sales_return.created_at.month, @sales_return.created_at.year, attr_warehouse_id, @sd.product_id, @sd.color_id, @sd.size_id]).first.quantity rescue nil if beginning_stock.nil?
              beginning_stock = 0 if beginning_stock.nil?                        
              stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: @sd.color_id,
                size_id: @sd.size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + 1)
              stock_movement_product_detail.stock_movement_transactions.build sales_return_quantity_received: 1, transaction_date: @sales_return.created_at.to_date
              stock_movement_product_detail.save
            else
              stock_movement_product_detail.with_lock do                                      
                stock_movement_product_detail.ending_stock += 1
                stock_movement_product_detail.stock_movement_transactions.build sales_return_quantity_received: 1, transaction_date: @sales_return.created_at.to_date
                stock_movement_product_detail.save
              end
            end
          end
        end
      end
    end
  end



end
