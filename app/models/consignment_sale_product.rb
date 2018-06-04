class ConsignmentSaleProduct < ApplicationRecord
  attr_accessor :attr_warehouse_id, :attr_barcode, :attr_delete_by_admin, :attr_delete_by_am
  
  belongs_to :consignment_sale
  belongs_to :product_barcode
  belongs_to :price_list
  
  after_create :add_afs
  before_destroy :delete_afs
  
  private
  
  def add_afs
    sd = StockDetail.joins(stock_product: [product: [product_colors: :product_barcodes], stock: :warehouse]).
      where(:"product_barcodes.id" => product_barcode_id, :"warehouses.is_active" => true).
      where(["stocks.warehouse_id = ?", attr_warehouse_id]).
      where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
      select(:id, :quantity, :unapproved_quantity).first
    if sd.present?
      puts "quantity => #{sd.quantity}"
      puts "unapproved quantity => #{sd.unapproved_quantity}"
      puts "afs => #{sd.quantity - sd.unapproved_quantity}"
      raise_error = false
      sd.with_lock do
        if sd.quantity < 1
          raise_error = true
        elsif sd.quantity - sd.unapproved_quantity < 1
          raise_error = true
        else
          sd.unapproved_quantity += 1
          sd.save
        end
      end
      raise "Sorry, product #{attr_barcode} is temporarily out of stock" if raise_error
    else
      raise "Product #{attr_barcode} is not available"
    end
  end

  def delete_afs
    sd = if !attr_delete_by_admin && !attr_delete_by_am
      StockDetail.joins(stock_product: [product: [product_colors: :product_barcodes], stock: :warehouse]).
        where(:"product_barcodes.id" => product_barcode_id, :"warehouses.is_active" => true).
        where(["stocks.warehouse_id = ?", attr_warehouse_id]).
        where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
        select(:id, :unapproved_quantity).first
    else
      if consignment_sale.warehouse_id.blank?
        StockDetail.
          joins(stock_product: [product: [product_colors: [product_barcodes: [consignment_sale_products: [consignment_sale: :audits]]]], stock: :warehouse]).
          joins("INNER JOIN users ON audits.user_id = users.id AND audits.user_type = 'User'").
          joins("INNER JOIN sales_promotion_girls ON users.sales_promotion_girl_id = sales_promotion_girls.id").
          where(:"product_barcodes.id" => product_barcode_id, :"warehouses.is_active" => true).
          where(["consignment_sale_products.id = ?", id]).
          where("audits.action = 'create'").
          where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id AND stocks.warehouse_id = sales_promotion_girls.warehouse_id").
          select(:id, :unapproved_quantity).first
      else
        StockDetail.joins(stock_product: [product: [product_colors: :product_barcodes], stock: :warehouse]).
          where(:"product_barcodes.id" => product_barcode_id, :"warehouses.is_active" => true).
          where(["stocks.warehouse_id = ?", consignment_sale.warehouse_id]).
          where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
          select(:id, :unapproved_quantity).first
      end
    end
    if sd.present?
      raise_error = false
      sd.with_lock do
        if sd.unapproved_quantity < 1
          raise_error = true
        else
          sd.unapproved_quantity -= 1
          sd.save
        end
      end
      raise "Something went wrong. Please try again" if raise_error
    else
      raise "Something went wrong. Please try again"
    end
  end
end
