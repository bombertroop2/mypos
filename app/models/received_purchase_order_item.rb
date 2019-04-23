class ReceivedPurchaseOrderItem < ApplicationRecord
  belongs_to :purchase_order_detail
  belongs_to :received_purchase_order_product
  belongs_to :direct_purchase_detail
  
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |rpoi| rpoi.quantity.present? }
    validate :less_than_or_equal_to_order, if: proc {|rpoi| rpoi.quantity.present? && rpoi.quantity > 0 && !rpoi.is_it_direct_purchasing}
      validates :purchase_order_detail_id, presence: true, if: proc{|rpoi| rpoi.direct_purchase_detail_id.blank?}
        validate :purchase_order_detail_receivable, if: proc{|rpoi| rpoi.direct_purchase_detail_id.blank?}
          validate :transaction_after_beginning_stock_added, on: :create, if: proc{Company.where(import_beginning_stock: true).select("1 AS one").present?}
      
            before_create :update_receiving_value, unless: proc {|rpoi| rpoi.is_it_direct_purchasing}
              before_create :create_stock_and_update_receiving_qty, unless: proc {|rpoi| rpoi.is_it_direct_purchasing}
                before_create :create_stock, if: proc {|rpoi| rpoi.is_it_direct_purchasing}
                  before_create :create_stock_movement
                  after_create :create_listing_stock
      
                  attr_accessor :is_it_direct_purchasing, :purchase_order_product_id,
                    :purchase_order_id, :receiving_date, :warehouse_id, :product_id,
                    :pod
    
                  private
                
                  def transaction_after_beginning_stock_added
                    color_id = unless is_it_direct_purchasing
                      purchase_order_detail.color_id
                    else
                      direct_purchase_detail.color_id
                    end
                    size_id = unless is_it_direct_purchasing
                      purchase_order_detail.size_id
                    else
                      direct_purchase_detail.size_id
                    end
                    listing_stock_transaction = ListingStockTransaction.select(:transaction_date).joins(listing_stock_product_detail: :listing_stock).where(transaction_type: "BS", :"listing_stock_product_details.color_id" => color_id, :"listing_stock_product_details.size_id" => size_id, :"listing_stocks.warehouse_id" => warehouse_id, :"listing_stocks.product_id" => product_id).first
                    errors.add(:base, "Sorry, you can't receive article on #{receiving_date.to_date.strftime("%d/%m/%Y")}") if listing_stock_transaction.present? && listing_stock_transaction.transaction_date > receiving_date.to_date
                  end
                
                  def create_listing_stock
                    color_id = unless is_it_direct_purchasing
                      purchase_order_detail.color_id
                    else
                      direct_purchase_detail.color_id
                    end
                    
                    size_id = unless is_it_direct_purchasing
                      purchase_order_detail.size_id
                    else
                      direct_purchase_detail.size_id
                    end
                    transaction = ReceivedPurchaseOrder.select(:transaction_number).joins(received_purchase_order_products: :received_purchase_order_items).where(["received_purchase_order_items.id = ?", id]).first
                    CreateListingStockJob.perform_later(warehouse_id, product_id, color_id, size_id, receiving_date, transaction.transaction_number, "PO", self.id, self.class.name, quantity)
                  end
                
                  def create_stock_movement
                    color_id = unless is_it_direct_purchasing
                      purchase_order_detail.color_id
                    else
                      direct_purchase_detail.color_id
                    end
                    size_id = unless is_it_direct_purchasing
                      purchase_order_detail.size_id
                    else
                      direct_purchase_detail.size_id
                    end
                    CreateStockMovementJob.perform_later(warehouse_id, product_id, color_id, size_id, receiving_date, quantity)
                  end
                
                  def purchase_order_detail_receivable
                    errors.add(:base, "Not able to receive selected items") unless PurchaseOrderDetail.select("1 AS one").joins(purchase_order_product: :purchase_order).where("(status = 'Open' OR status = 'Partial') AND purchase_orders.id = '#{purchase_order_id}' AND purchase_order_products.id = '#{purchase_order_product_id}' AND purchase_order_details.id = '#{purchase_order_detail_id}'").present?
                  end
      
      
                  def update_receiving_value
                    raise_error = false
                    purchase_order = received_purchase_order_product.received_purchase_order.purchase_order
                    purchase_order.with_lock do
                      if purchase_order.receiving_value.nil? || purchase_order.receiving_value < purchase_order.order_value
                        purchase_order.receiving_po = true
                        purchase_order.receiving_value = purchase_order.receiving_value.to_f + received_purchase_order_product.purchase_order_product.cost_list.cost * quantity
                        if purchase_order.receiving_value < purchase_order.order_value
                          purchase_order.status = "Partial"
                          purchase_order.without_auditing do
                            purchase_order.save validate: false
                          end                      
                        elsif purchase_order.receiving_value == purchase_order.order_value
                          purchase_order.status = "Finish"
                          purchase_order.without_auditing do
                            purchase_order.save validate: false
                          end                      
                        else
                          raise_error = true
                        end
                      else
                        raise_error = true                      
                      end
                    end
                  
                    raise "Sorry, purchase order #{purchase_order.number} has already been finished" if raise_error
                  end
    
                  def less_than_or_equal_to_order
                    remains_quantity = purchase_order_detail.quantity - purchase_order_detail.receiving_qty.to_i
                    errors.add(:quantity, "must be less than or equal to remaining ordered quantity.") if quantity > remains_quantity
                  end
      
                  def create_stock_and_update_receiving_qty
                    raise_error = false
                    purchase_order_detail.with_lock do
                      remains_quantity = purchase_order_detail.quantity - purchase_order_detail.receiving_qty.to_i
                      if quantity <= remains_quantity
                        purchase_order_detail.is_updating_receiving_quantity = true
                        purchase_order_detail.receiving_qty = purchase_order_detail.receiving_qty.to_i + quantity
                        purchase_order_detail.save
                      else
                        raise_error = true
                      end
                    end
                    raise "Quantity must be less than or equal to remaining ordered quantity." if raise_error

                    stock = Stock.where(warehouse_id: warehouse_id).select(:id).first
                    stock = Stock.new warehouse_id: warehouse_id if stock.blank?
                    product = purchase_order_detail.purchase_order_product.product
                    if stock.new_record?
                      stock_product = stock.stock_products.build product_id: product.id
                      stock_detail = stock_product.stock_details.build size_id: purchase_order_detail.size_id, color_id: purchase_order_detail.color_id, quantity: quantity
                      stock.save
                    else
                      stock_product = stock.stock_products.select{|sp| sp.product_id.eql?(product.id)}.first
                      stock_product = stock.stock_products.build product_id: product.id if stock_product.blank?
                      if stock_product.new_record?                      
                        stock_detail = stock_product.stock_details.build size_id: purchase_order_detail.size_id, color_id: purchase_order_detail.color_id, quantity: quantity
                        stock_product.save
                      else
                        stock_detail = stock_product.stock_details.select{|stock_detail| stock_detail.size_id == purchase_order_detail.size_id && stock_detail.color_id == purchase_order_detail.color_id}.first
                        stock_detail = stock_product.stock_details.build size_id: purchase_order_detail.size_id, color_id: purchase_order_detail.color_id, quantity: quantity if stock_detail.blank?
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
                  end
      
                  def create_stock
                    direct_purchase_product = DirectPurchaseProduct.select(:product_id, :direct_purchase_id, :product_id).where(id: direct_purchase_detail.direct_purchase_product_id).first
                    warehouse = Warehouse.joins(:direct_purchases).where(["direct_purchases.id = ?", direct_purchase_product.direct_purchase_id]).select(:id).first
                    stock = Stock.select(:id).where(warehouse_id: warehouse.id).first
                    stock = Stock.new warehouse_id: warehouse.id if stock.blank?
                    product = Product.select(:id).where(id: direct_purchase_product.product_id).first
                    if stock.new_record?                    
                      stock_product = stock.stock_products.build product_id: product.id
                      stock_detail = stock_product.stock_details.build size_id: direct_purchase_detail.size_id, color_id: direct_purchase_detail.color_id, quantity: direct_purchase_detail.quantity
                      stock.save
                    else
                      stock_product = stock.stock_products.select(:id).where(product_id: product.id).first
                      stock_product = stock.stock_products.build product_id: product.id if stock_product.blank?
                      if stock_product.new_record?                      
                        stock_detail = stock_product.stock_details.build size_id: direct_purchase_detail.size_id, color_id: direct_purchase_detail.color_id, quantity: direct_purchase_detail.quantity
                        stock_product.save
                      else
                        stock_detail = stock_product.stock_details.select(:id, :quantity).where(size_id: direct_purchase_detail.size_id, color_id: direct_purchase_detail.color_id).first
                        stock_detail = stock_product.stock_details.build size_id: direct_purchase_detail.size_id, color_id: direct_purchase_detail.color_id, quantity: direct_purchase_detail.quantity if stock_detail.blank?
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
                  end

                end
