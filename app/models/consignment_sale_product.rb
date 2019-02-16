class ConsignmentSaleProduct < ApplicationRecord
  attr_accessor :attr_warehouse_id, :attr_barcode, :attr_delete_by_admin, :attr_delete_by_am,
    :attr_transaction_date, :attr_parent_id, :attr_delete_products, :attr_no_sale, :attr_importing_data
  
  belongs_to :consignment_sale
  belongs_to :product_barcode
  belongs_to :price_list
  
  validate :transaction_after_beginning_stock_added, on: :create, if: proc{|csp| !csp.attr_importing_data && Company.where(import_beginning_stock: true).select("1 AS one").present?}
  
    after_create :next_transaction_not_created, :add_afs, unless: proc{|csp| csp.attr_importing_data}
      before_destroy :record_has_correct_parent, :delete_afs
  
      private
      
      def transaction_after_beginning_stock_added
        product_barcode = ProductBarcode.select(:size_id, :color_id, :product_id).joins(:product_color).where(id: product_barcode_id).first
        listing_stock_transaction = ListingStockTransaction.select(:transaction_date).joins(listing_stock_product_detail: :listing_stock).where(transaction_type: "BS", :"listing_stock_product_details.color_id" => product_barcode.color_id, :"listing_stock_product_details.size_id" => product_barcode.size_id, :"listing_stocks.warehouse_id" => attr_warehouse_id, :"listing_stocks.product_id" => product_barcode.product_id).first
        errors.add(:base, "Sorry, you can't perform transaction on #{attr_transaction_date.to_date.strftime("%d/%m/%Y")}") if listing_stock_transaction.present? && listing_stock_transaction.transaction_date > attr_transaction_date.to_date
      end
    
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
              adjustment_product_details = AdjustmentProductDetail.
                select(:quantity).joins(adjustment_product: :adjustment).
                where(["adjustment_product_details.size_id = ? AND adjustment_product_details.color_id = ?", sd.size_id, sd.color_id]).
                where(["adjustment_products.product_id = ?", product_id]).
                where(["adjustments.warehouse_id = ? AND adjustments.adj_type = 'In'", attr_warehouse_id]).
                where(["adjustments.adj_date > ?", attr_transaction_date.to_date]).
                order("adjustments.adj_date ASC")
              # hitung total stok rolling out di tanggal setelah tanggal transaksi penjualan
              rolling_out_items = StockMutationProductItem.
                joins(stock_mutation_product: [stock_mutation: :destination_warehouse]).
                where(["stock_mutation_product_items.size_id = ? AND stock_mutation_product_items.color_id = ?", sd.size_id, sd.color_id]).
                where(["stock_mutation_products.product_id = ?", product_id]).
                where(["stock_mutations.origin_warehouse_id = ?", attr_warehouse_id]).
                where("warehouses.warehouse_type <> 'central'").
                where(["stock_mutations.delivery_date > ?", attr_transaction_date.to_date]).
                select(:quantity).order("stock_mutations.delivery_date ASC")

              # hitung total stok return di tanggal setelah tanggal transaksi penjualan
              return_items = StockMutationProductItem.
                joins(stock_mutation_product: [stock_mutation: :destination_warehouse]).
                where(["stock_mutation_product_items.size_id = ? AND stock_mutation_product_items.color_id = ?", sd.size_id, sd.color_id]).
                where(["stock_mutation_products.product_id = ?", product_id]).
                where(["stock_mutations.origin_warehouse_id = ?", attr_warehouse_id]).
                where("warehouses.warehouse_type = 'central'").
                where(["stock_mutations.delivery_date > ?", attr_transaction_date.to_date]).
                select(:quantity).order("stock_mutations.delivery_date ASC")
              do_qty_on_hand = shipment_items.present? ? shipment_items.sum(&:quantity) : 0
              mutation_qty_on_hand = stock_mutation_product_items.present? ? stock_mutation_product_items.sum(&:quantity) : 0
              adj_in_qty_on_hand = adjustment_product_details.present? ? adjustment_product_details.sum(&:quantity) : 0
              rolling_out_qty = rolling_out_items.present? ? rolling_out_items.sum(&:quantity) : 0
              return_qty = return_items.present? ? return_items.sum(&:quantity) : 0
              qty_on_hand_before_inv_receipt = sd.quantity - (do_qty_on_hand + mutation_qty_on_hand + adj_in_qty_on_hand - rolling_out_qty - return_qty)
              if qty_on_hand_before_inv_receipt < 1
                error_message = "Sorry, available quantity of product #{attr_barcode} on #{attr_transaction_date} is #{qty_on_hand_before_inv_receipt}"
                raise_error = true
              else
                if do_qty_on_hand > 0 || mutation_qty_on_hand > 0 || adj_in_qty_on_hand > 0 || rolling_out_qty > 0 || return_qty > 0
                  # hitung jumlah booked quantity sebelum penerimaan inventory dikurangi booked quantity di penjualan ini
                  booked_quantity_before_inv_receipt = ConsignmentSaleProduct.joins(:consignment_sale).
                    where(["consignment_sale_products.product_barcode_id = ? AND consignment_sales.approved = ? AND consignment_sales.transaction_date <= ? AND consignment_sales.warehouse_id = ? AND consignment_sales.id <> ?", product_barcode_id, false, attr_transaction_date.to_date, attr_warehouse_id, consignment_sale_id]).
                    size
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
        sd = StockDetail.joins(stock_product: [product: [product_colors: :product_barcodes], stock: :warehouse]).
          where(:"product_barcodes.id" => product_barcode_id, :"warehouses.is_active" => true).
          where(["stocks.warehouse_id = ?", consignment_sale.warehouse_id]).
          where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
          select(:id, :unapproved_quantity).first
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