class CashierOpening < ApplicationRecord
  attr_accessor :update_cash_balance, :closing_cashier, :user_id
  
  belongs_to :warehouse
  belongs_to :user, class_name: "User", foreign_key: :opened_by
  has_many :cash_disbursements, dependent: :destroy
  has_many :sales
  
  before_validation :set_open_time, if: proc{|co| !co.update_cash_balance && !co.closing_cashier}
  
    validates :shift, :station, :beginning_cash, presence: true, if: proc{|co| !co.update_cash_balance && !co.closing_cashier}
      validates :beginning_cash, numericality: {greater_than_or_equal_to: 0}, if: proc { |co| !co.update_cash_balance && co.beginning_cash.present? && !co.closing_cashier}
        validates :station, uniqueness: { scope: [:warehouse_id, :open_date, :shift], message: "has already been opened" }, if: proc{|co| !co.update_cash_balance && !co.closing_cashier}
          validate :station_available, :shift_available, :second_shift_allowable, :today_cashier_openable, if: proc{|co| !co.update_cash_balance && !co.closing_cashier}
            validate :closable, if: proc{|co| co.closing_cashier}
              validate :warehouse_is_open

              before_create :set_cash_balance
              before_update :calculate_total_sales, if: proc{|co| co.closing_cashier}
    
                STATIONS = [
                  ["1", "1"],
                  ["2", "2"],
                  ["3", "3"]
                ]

                SHIFTS = [
                  ["1", "1"],
                  ["2", "2"]
                ]
    

                private
                
                def warehouse_is_open
                  warehouse_id = self.warehouse_id rescue nil
                  errors.add(:base, "Sorry, warehouse is not active") if warehouse_id.present? && Warehouse.select("1 AS one").where(id: warehouse_id).where(["warehouses.is_active = ? AND warehouses.warehouse_type = 'showroom'", true]).blank?
                end
              
                def calculate_total_sales
                  sale_products = SaleProduct.joins(:price_list, sale: :cashier_opening).
                    joins("LEFT JOIN banks ON sales.bank_id = banks.id").
                    joins("LEFT JOIN events ON sale_products.event_id = events.id").
                    joins("LEFT JOIN events gift_events ON sales.gift_event_id = gift_events.id").
                    where(["sales.cashier_opening_id = ? AND sales.sales_return_id IS NULL", id]).
                    select(:sale_id, :quantity, "sale_products.total AS subtotal", :event_id, "sales.gift_event_id", "sales.payment_method", "banks.card_type", "price_lists.price AS article_price", "events.event_type AS article_event_type", "gift_events.discount_amount AS store_discount_amount", "sales.gift_event_product_id", "sales.member_discount AS sale_member_discount", "sales.transaction_number", "banks.code AS bank_code").
                    order("sales.transaction_number ASC")

                  gross_sales = 0
                  net_sales = 0
                  cash_payment = 0
                  card_payment = 0
                  total_debits = 0
                  total_credits = 0
                  total_quantity = 0
                  total_gift_quantity = 0
                  sale_products.each_with_index do |sale_product, index|
                    if sale_product.event_id.blank? && sale_product.gift_event_id.blank?
                      total_quantity += 1
                      gross_sales += sale_product.article_price
                      net_sales += sale_product.subtotal
                      if sale_product.payment_method.eql?("Cash")
                        cash_payment += sale_product.subtotal
                      elsif sale_product.payment_method.eql?("Card")
                        card_payment += sale_product.subtotal
                        if sale_product.card_type.eql?("Credit")
                          total_credits += sale_product.subtotal
                        else
                          total_debits += sale_product.subtotal
                        end
                      end
                    elsif sale_product.gift_event_id.blank?
                      if sale_product.article_event_type.eql?("Buy 1 Get 1 Free")
                        total_quantity += 2
                      else
                        total_quantity += 1
                      end
                      gross_sales += sale_product.article_price
                      net_sales += sale_product.subtotal
                      if sale_product.payment_method.eql?("Cash")
                        cash_payment += sale_product.subtotal
                      elsif sale_product.payment_method.eql?("Card")
                        card_payment += sale_product.subtotal
                        if sale_product.card_type.eql?("Credit")
                          total_credits += sale_product.subtotal
                        else
                          total_debits += sale_product.subtotal
                        end
                      end
                      #                    else
                      #                      sale_product_quantity_per_transaction_number = sale_products.select{|sp| sp.transaction_number == sale_product.transaction_number}.length
                      #                      total_quantity += 1
                      #                      gross_sales += sale_product.article_price
                      #                      subtotal = if sale_product.gift_event_product_id.blank?
                      #                        if sale_product.sale_member_discount.present? && sale_product.sale_member_discount > 0
                      #                          subtotal_before_member_discount = (sale_product.subtotal * 100).to_f / (100 - sale_product.sale_member_discount)
                      #                          subtotal_after_gift_discount = subtotal_before_member_discount - (sale_product.store_discount_amount.to_f / sale_product_quantity_per_transaction_number)
                      #                          subtotal_after_gift_discount - subtotal_after_gift_discount * (sale_product.sale_member_discount.to_f / 100)
                      #                        else
                      #                          sale_product.subtotal - (sale_product.store_discount_amount.to_f / sale_product_quantity_per_transaction_number)
                      #                        end
                      #                      else
                      #                        sale_product.subtotal
                      #                      end
                      #                      net_sales += subtotal
                      #                      if sale_product.payment_method.eql?("Cash")
                      #                        cash_subtotal = if sale_product.gift_event_product_id.blank?
                      #                          if sale_product.sale_member_discount.present? && sale_product.sale_member_discount > 0
                      #                            subtotal_before_member_discount = (sale_product.subtotal * 100).to_f / (100 - sale_product.sale_member_discount)
                      #                            subtotal_after_gift_discount = subtotal_before_member_discount - (sale_product.store_discount_amount.to_f / sale_product_quantity_per_transaction_number)
                      #                            subtotal_after_gift_discount - subtotal_after_gift_discount * (sale_product.sale_member_discount.to_f / 100)
                      #                          else
                      #                            sale_product.subtotal - (sale_product.store_discount_amount.to_f / sale_product_quantity_per_transaction_number)
                      #                          end
                      #                        else
                      #                          sale_product.subtotal
                      #                        end
                      #                        cash_payment += cash_subtotal
                      #                      elsif sale_product.payment_method.eql?("Card")
                      #                        card_subtotal = if sale_product.gift_event_product_id.blank?
                      #                          if sale_product.sale_member_discount.present? && sale_product.sale_member_discount > 0
                      #                            subtotal_before_member_discount = (sale_product.subtotal * 100).to_f / (100 - sale_product.sale_member_discount)
                      #                            subtotal_after_gift_discount = subtotal_before_member_discount - (sale_product.store_discount_amount.to_f / sale_product_quantity_per_transaction_number)
                      #                            subtotal_after_gift_discount - subtotal_after_gift_discount * (sale_product.sale_member_discount.to_f / 100)
                      #                          else
                      #                            sale_product.subtotal - (sale_product.store_discount_amount.to_f / sale_product_quantity_per_transaction_number)
                      #                          end
                      #                        else
                      #                          sale_product.subtotal
                      #                        end
                      #                        unless sale_product.bank_code.eql?("MEMO")
                      #                          card_payment += card_subtotal
                      #                          if sale_product.card_type.eql?("Credit")
                      #                            credit_card_subtotal = if sale_product.gift_event_product_id.blank?
                      #                              if sale_product.sale_member_discount.present? && sale_product.sale_member_discount > 0
                      #                                subtotal_before_member_discount = (sale_product.subtotal * 100).to_f / (100 - sale_product.sale_member_discount)
                      #                                subtotal_after_gift_discount = subtotal_before_member_discount - (sale_product.store_discount_amount.to_f / sale_product_quantity_per_transaction_number)
                      #                                subtotal_after_gift_discount - subtotal_after_gift_discount * (sale_product.sale_member_discount.to_f / 100)
                      #                              else
                      #                                sale_product.subtotal - (sale_product.store_discount_amount.to_f / sale_product_quantity_per_transaction_number)
                      #                              end
                      #                            else
                      #                              sale_product.subtotal
                      #                            end
                      #                            total_credits += credit_card_subtotal
                      #                          else
                      #                            debit_card_subtotal = if sale_product.gift_event_product_id.blank?
                      #                              if sale_product.sale_member_discount.present? && sale_product.sale_member_discount > 0
                      #                                subtotal_before_member_discount = (sale_product.subtotal * 100).to_f / (100 - sale_product.sale_member_discount)
                      #                                subtotal_after_gift_discount = subtotal_before_member_discount - (sale_product.store_discount_amount.to_f / sale_product_quantity_per_transaction_number)
                      #                                subtotal_after_gift_discount - subtotal_after_gift_discount * (sale_product.sale_member_discount.to_f / 100)
                      #                              else
                      #                                sale_product.subtotal - (sale_product.store_discount_amount.to_f / sale_product_quantity_per_transaction_number)
                      #                              end
                      #                            else
                      #                              sale_product.subtotal
                      #                            end
                      #                            total_debits += debit_card_subtotal
                      #                          end
                      #                        else
                      #                          memo_payment += sale_product.subtotal
                      #                        end
                      #                      end
                      #                      if sale_product.gift_event_product_id.present? && sale_products[index + 1].transaction_number != sale_product.transaction_number
                      #                        total_gift_quantity += 1
                      #                      elsif sale_product.gift_event_product_id.present? && index == sale_products.length - 1
                      #                        total_gift_quantity += 1
                      #                      end
                    end
                  end
                  
                  sales_return_products = SaleProduct.joins(:price_list, sale: :cashier_opening, returned_product: :price_list).
                    select("sale_products.total AS subtotal", "sales.payment_method", "banks.card_type", "price_lists.price AS replacement_article_price", "price_lists_sale_products.price AS returned_article_price", "returned_products_sale_products.total AS returned_subtotal").
                    joins("LEFT JOIN banks ON sales.bank_id = banks.id").
                    where(["sales.cashier_opening_id = ? AND sales.sales_return_id IS NOT NULL", id]).
                    order("sales.transaction_number ASC")

                  sales_return_products.each_with_index do |sales_return_product, index|
                    if sales_return_product.replacement_article_price.to_f > sales_return_product.returned_article_price.to_f
                      gross_sales = gross_sales + (sales_return_product.replacement_article_price.to_f - sales_return_product.returned_article_price.to_f)
                    end
                    if sales_return_product.subtotal.to_f > sales_return_product.returned_subtotal.to_f
                      net_sales = net_sales + (sales_return_product.subtotal.to_f - sales_return_product.returned_subtotal.to_f)
                    end
                    if sales_return_product.payment_method.eql?("Cash")
                      if sales_return_product.subtotal.to_f > sales_return_product.returned_subtotal.to_f
                        cash_payment = cash_payment + (sales_return_product.subtotal.to_f - sales_return_product.returned_subtotal.to_f)
                      end
                    elsif sales_return_product.payment_method.eql?("Card")
                      if sales_return_product.subtotal.to_f > sales_return_product.returned_subtotal.to_f
                        card_payment = card_payment + (sales_return_product.subtotal.to_f - sales_return_product.returned_subtotal.to_f)
                      end
                      if sales_return_product.card_type.eql?("Credit")
                        if sales_return_product.subtotal.to_f > sales_return_product.returned_subtotal.to_f
                          total_credits = total_credits + (sales_return_product.subtotal.to_f - sales_return_product.returned_subtotal.to_f)
                        end
                      else
                        if sales_return_product.subtotal.to_f > sales_return_product.returned_subtotal.to_f
                          total_debits = total_debits + (sales_return_product.subtotal.to_f - sales_return_product.returned_subtotal.to_f)
                        end
                      end
                    end
                  end
                  
                  self.net_sales = net_sales
                  self.gross_sales = gross_sales
                  self.cash_payment = cash_payment
                  self.card_payment = card_payment
                  self.debit_card_payment = total_debits
                  self.credit_card_payment = total_credits
                  self.total_quantity = total_quantity
                  self.total_gift_quantity = total_gift_quantity
                end
            
                def closable
                  self.closed_at = open_date.end_of_day if open_date != Date.current
                  warehouse_id = self.warehouse_id rescue nil
                  if warehouse_id.present? && Warehouse.select("1 AS one").where(id: warehouse_id).where(["warehouses.is_active = ?", true]).blank?
                    errors.add(:base, "Sorry, warehouse is not active")
                  else
                    errors.add(:base, "Sorry, cashier cannot be closed") if opened_by != user_id || closed_at_was.present?
                  end
                end
    
                def set_cash_balance
                  self.cash_balance = beginning_cash
                end
    
                def today_cashier_openable
                  errors.add(:base, "Previous cashier is open, please close it first") if CashierOpening.joins(:warehouse).select("1 AS one").where(warehouse_id: warehouse_id).where("closed_at IS NULL").where(["open_date <> ? AND warehouses.is_active = ?", @current_date, true]).where("opened_by = #{opened_by}").present?
                end
    
                def second_shift_allowable      
                  first_shift = CashierOpening.joins(:warehouse).select(:closed_at).where(warehouse_id: warehouse_id, station: station, shift: "1", open_date: @current_date).where(["warehouses.is_active = ?", true]).first
                  errors.add(:shift, "is not allowed!") if shift.eql?("2") && station.present? && (first_shift.blank? || first_shift.closed_at.nil?)
                end
    
                def station_available
                  STATIONS.select{ |x| x[1] == station }.first.first
                rescue
                  errors.add(:station, "does not exist!") if station.present?
                end

                def shift_available
                  SHIFTS.select{ |x| x[1] == shift }.first.first
                rescue
                  errors.add(:shift, "does not exist!") if shift.present?
                end
      
                def set_open_time
                  @current_date = Date.current
                  self.open_date = @current_date
                end
              end
