class ConsignmentSaleProduct < ApplicationRecord
  attr_accessor :attr_warehouse_id, :attr_barcode, :attr_delete_by_admin, :attr_delete_by_am,
    :attr_transaction_date, :attr_parent_id, :attr_delete_products
  
  belongs_to :consignment_sale
  belongs_to :product_barcode
  belongs_to :price_list
  
  after_create :next_transaction_not_created, :add_afs
  before_destroy :record_has_correct_parent, :delete_afs
  
  private
    
  def record_has_correct_parent    
    raise "Record does not exist!" if attr_parent_id != consignment_sale_id && attr_delete_products
  end
    
  def next_transaction_not_created
    raise "Please delete all transactions after #{attr_transaction_date.to_date.strftime("%d/%m/%Y")} which contain product #{attr_barcode} first" if ConsignmentSale.select("1 AS one").joins(:consignment_sale_products).where(["consignment_sales.transaction_date > ? AND consignment_sales.warehouse_id = ? AND consignment_sale_products.product_barcode_id = ?", attr_transaction_date.to_date, attr_warehouse_id, product_barcode_id]).present?
  end
  
  def add_afs
    sd = StockDetail.joins(stock_product: [product: [product_colors: :product_barcodes], stock: :warehouse]).
      where(:"product_barcodes.id" => product_barcode_id, :"warehouses.is_active" => true).
      where(["stocks.warehouse_id = ?", attr_warehouse_id]).
      where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
      select(:id, :quantity, :unapproved_quantity, :size_id, :color_id, "stock_products.product_id").first
    if sd.present?
      product_id = sd.product_id
      error_message = "Sorry, product #{attr_barcode} is temporarily out of stock"
      raise_error = false
      sd.with_lock do
        if sd.quantity < 1
          raise_error = true
        elsif sd.quantity - sd.unapproved_quantity < 1
          raise_error = true
        else
          shipment_items = ShipmentProductItem.
            joins(order_booking_product_item: [order_booking_product: :order_booking], shipment_product: :shipment).
            where(["order_booking_product_items.size_id = ? AND order_booking_product_items.color_id = ?", sd.size_id, sd.color_id]).
            where(["order_booking_products.product_id = ?", product_id]).
            where(["order_bookings.destination_warehouse_id = ?", attr_warehouse_id]).
            where(["shipments.received_date > ?", attr_transaction_date.to_date]).
            select(:quantity, "shipments.received_date").order("shipments.received_date ASC")
          stock_mutation_product_items = StockMutationProductItem.
            joins(stock_mutation_product: :stock_mutation).
            where(["stock_mutation_product_items.size_id = ? AND stock_mutation_product_items.color_id = ?", sd.size_id, sd.color_id]).
            where(["stock_mutation_products.product_id = ?", product_id]).
            where(["stock_mutations.destination_warehouse_id = ?", attr_warehouse_id]).
            where(["stock_mutations.received_date > ?", attr_transaction_date.to_date]).
            select(:quantity, "stock_mutations.received_date").order("stock_mutations.received_date ASC")
          do_qty_on_hand = shipment_items.present? ? shipment_items.sum(&:quantity) : 0
          mutation_qty_on_hand = stock_mutation_product_items.present? ? stock_mutation_product_items.sum(&:quantity) : 0
          qty_on_hand_before_inv_receipt = sd.quantity - (do_qty_on_hand + mutation_qty_on_hand)
          if qty_on_hand_before_inv_receipt < 1
            error_message = "Sorry, available quantity of product #{attr_barcode} on #{attr_transaction_date} is #{qty_on_hand_before_inv_receipt}"
            raise_error = true
          else
            if do_qty_on_hand > 0 || mutation_qty_on_hand > 0
              # hitung jumlah booked quantity sebelum penerimaan inventory dikurangi booked quantity di penjualan ini
              current_consignment_sale_id = ConsignmentSale.select(:id).where(id: consignment_sale_id).first.id
              booked_quantity_before_inv_receipt = ConsignmentSaleProduct.joins(:consignment_sale).
                where(["consignment_sale_products.product_barcode_id = ? AND consignment_sales.approved = ? AND consignment_sales.transaction_date <= ? AND consignment_sales.warehouse_id = ? AND consignment_sales.id <> ?", product_barcode_id, false, attr_transaction_date.to_date, attr_warehouse_id, current_consignment_sale_id]).
                size rescue 0
              if qty_on_hand_before_inv_receipt - booked_quantity_before_inv_receipt < 1
                error_message = "Sorry, product #{attr_barcode} on #{attr_transaction_date} is temporarily out of stock"
                raise_error = true
              else
                sd.unapproved_quantity += 1
                sd.save
              end
            else
              sd.unapproved_quantity += 1
              sd.save
            end
          end
        end
      end
      raise error_message if raise_error
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
