class BeginningStockProductDetail < ApplicationRecord
  belongs_to :beginning_stock_product
  belongs_to :color
  belongs_to :size
  
  after_create :create_listing_stock
  
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
end
