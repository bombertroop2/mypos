class AdjustmentProductDetail < ApplicationRecord
  attr_accessor :attr_color_code, :attr_color_name, :attr_size, :attr_warehouse_id, :attr_adj_date, :attr_product_id
  belongs_to :adjustment_product
  belongs_to :color
  belongs_to :size
  
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}  
  validate :product_available
  validate :transaction_after_beginning_stock_added
  
  after_create :load_goods_to_destination_warehouse
  
  private
  
  def product_available
    if Product.select("1 AS one").joins(:product_colors, :product_details).where(id: attr_product_id).where(["product_colors.color_id = ?", color_id]).where(["product_details.size_id = ?", size_id]).blank?
      errors.add(:base, "Product #{attr_product_id} does not exist!")      
    end
  end
  
  def create_listing_stock(product_id, color_id, size_id, warehouse_id, transaction_date, quantity)
    listing_stock = ListingStock.select(:id).where(warehouse_id: warehouse_id, product_id: product_id).first
    listing_stock = ListingStock.new warehouse_id: warehouse_id, product_id: product_id if listing_stock.blank?
    if listing_stock.new_record?
      listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id
      listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: adjustment_product.adjustment.number, transaction_type: "ADI", transactionable_id: self.id, transactionable_type: self.class.name, quantity: quantity
      listing_stock.save
    else
      listing_stock_product_detail = listing_stock.listing_stock_product_details.where(color_id: color_id, size_id: size_id).select(:id).first
      listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id if listing_stock_product_detail.blank?
      if listing_stock_product_detail.new_record?
        listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: adjustment_product.adjustment.number, transaction_type: "ADI", transactionable_id: self.id, transactionable_type: self.class.name, quantity: quantity
        listing_stock_product_detail.save
      else
        listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: adjustment_product.adjustment.number, transaction_type: "ADI", transactionable_id: self.id, transactionable_type: self.class.name, quantity: quantity
        listing_stock_transaction.save
      end
    end
  end
  
  def create_stock_movement(product_id, color_id, size_id, warehouse_id, transaction_date, quantity)
    next_month_movements = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:id, :beginning_stock, :ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date >= ?", warehouse_id, product_id, color_id, size_id, transaction_date.next_month.beginning_of_month]).group(:id, :beginning_stock, :ending_stock)
    next_month_movements.each do |next_month_movement|
      next_month_movement.with_lock do
        next_month_movement.beginning_stock += quantity
        next_month_movement.ending_stock += quantity
        next_month_movement.save
      end
    end

    stock_movement = StockMovement.select(:id).where(year: transaction_date.year).first
    stock_movement = StockMovement.new year: transaction_date.year if stock_movement.blank?
    if stock_movement.new_record?
      beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
      beginning_stock = 0 if beginning_stock.nil?
      stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month
      stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
      stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
      stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
        size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
      stock_movement_product_detail.stock_movement_transactions.build adjustment_in_quantity: quantity, transaction_date: transaction_date
      stock_movement.save
    else
      stock_movement_month = stock_movement.stock_movement_months.select(:id).where(month: transaction_date.month).first
      stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month if stock_movement_month.blank?
      if stock_movement_month.new_record?
        beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
        beginning_stock = 0 if beginning_stock.nil?
        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
        stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
        stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
          size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
        stock_movement_product_detail.stock_movement_transactions.build adjustment_in_quantity: quantity, transaction_date: transaction_date
        stock_movement_month.save
      else
        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select(:id).where(warehouse_id: warehouse_id).first
        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id if stock_movement_warehouse.blank?
        if stock_movement_warehouse.new_record?
          beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
          beginning_stock = 0 if beginning_stock.nil?
          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
          stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
            size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
          stock_movement_product_detail.stock_movement_transactions.build adjustment_in_quantity: quantity, transaction_date: transaction_date
          stock_movement_warehouse.save
        else
          stock_movement_product = stock_movement_warehouse.stock_movement_products.select(:id).where(product_id: product_id).first
          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id if stock_movement_product.blank?
          if stock_movement_product.new_record?
            beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
            beginning_stock = 0 if beginning_stock.nil?
            stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
              size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
            stock_movement_product_detail.stock_movement_transactions.build adjustment_in_quantity: quantity, transaction_date: transaction_date
            stock_movement_product.save
          else
            stock_movement_product_detail = stock_movement_product.stock_movement_product_details.select(:id, :ending_stock).
              where(color_id: color_id, size_id: size_id).first
            if stock_movement_product_detail.blank?
              beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
              beginning_stock = 0 if beginning_stock.nil?
              stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
              stock_movement_product_detail.stock_movement_transactions.build adjustment_in_quantity: quantity, transaction_date: transaction_date
              stock_movement_product_detail.save
            else
              stock_movement_product_detail.with_lock do
                stock_movement_product_detail.ending_stock += quantity
                stock_movement_product_detail.stock_movement_transactions.build adjustment_in_quantity: quantity, transaction_date: transaction_date
                stock_movement_product_detail.save
              end
            end
          end
        end
      end
    end
  end
  
  def load_goods_to_destination_warehouse
    warehouse_id = Warehouse.select(:id).not_in_transit.not_direct_sales.actived.find(attr_warehouse_id).id
    stock = Stock.select(:id).where(warehouse_id: warehouse_id).first
    stock = Stock.new warehouse_id: warehouse_id if stock.blank?
    if stock.new_record?
      stock_product = stock.stock_products.build product_id: attr_product_id
      stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: quantity
      stock.save
    else
      stock_product = stock.stock_products.select(:id).where(product_id: attr_product_id).first
      stock_product = stock.stock_products.build product_id: attr_product_id if stock_product.blank?
      if stock_product.new_record?
        stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: quantity
        stock_product.save
      else
        stock_detail = stock_product.stock_details.select(:id, :quantity).where(size_id: size_id, color_id: color_id).first
        stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: quantity if stock_detail.blank?
        if stock_detail.new_record?
          stock_detail.save
        else
          stock_detail.with_lock do
            stock_detail.quantity += quantity
            stock_detail.save
          end
        end
      end
    end
    create_stock_movement(attr_product_id, color_id, size_id, warehouse_id, attr_adj_date.to_date, quantity)
    create_listing_stock(attr_product_id, color_id, size_id, warehouse_id, attr_adj_date.to_date, quantity)
  end
  
  def transaction_after_beginning_stock_added
    listing_stock_transaction = ListingStockTransaction.select(:transaction_date).joins(listing_stock_product_detail: :listing_stock).where(transaction_type: "BS", :"listing_stock_product_details.color_id" => color_id, :"listing_stock_product_details.size_id" => size_id, :"listing_stocks.warehouse_id" => attr_warehouse_id, :"listing_stocks.product_id" => attr_product_id).first
    if listing_stock_transaction.present? && listing_stock_transaction.transaction_date > attr_adj_date.to_date
      errors.add(:base, "Sorry, you can't perform transaction on #{attr_adj_date.strftime("%d/%m/%Y")}")
    end
  end
end
