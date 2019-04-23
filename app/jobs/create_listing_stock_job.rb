# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class CreateListingStockJob < ApplicationJob
  queue_as :default
  def perform(warehouse_id, product_id, color_id, size_id, transaction_date, transaction_number, transaction_type, transactionable_id, transactionable_type, quantity)
    transaction_date = transaction_date.to_date
    listing_stock = ListingStock.select(:id).where(warehouse_id: warehouse_id, product_id: product_id).first
    listing_stock = ListingStock.new warehouse_id: warehouse_id, product_id: product_id if listing_stock.blank?
    if listing_stock.new_record?                    
      listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id
      listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: transaction_number, transaction_type: transaction_type, transactionable_id: transactionable_id, transactionable_type: transactionable_type, quantity: quantity
      listing_stock.save
    else
      listing_stock_product_detail = listing_stock.listing_stock_product_details.where(color_id: color_id, size_id: size_id).select(:id).first
      listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id if listing_stock_product_detail.blank?
      if listing_stock_product_detail.new_record?
        listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: transaction_number, transaction_type: transaction_type, transactionable_id: transactionable_id, transactionable_type: transactionable_type, quantity: quantity
        listing_stock_product_detail.save
      else
        listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: transaction_number, transaction_type: transaction_type, transactionable_id: transactionable_id, transactionable_type: transactionable_type, quantity: quantity
        listing_stock_transaction.save
      end
    end
  end
end