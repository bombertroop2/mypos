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
              
                def calculate_total_sales
                  sale_products = SaleProduct.joins(:price_list, sale: :cashier_opening).
                    joins("LEFT JOIN banks ON sales.bank_id = banks.id").
                    joins("LEFT JOIN events ON sale_products.event_id = events.id").
                    joins("LEFT JOIN events gift_events ON sales.gift_event_id = gift_events.id").
                    where(["sales.cashier_opening_id = ?", id]).
                    select(:sale_id, :quantity, "sale_products.total AS subtotal", :event_id, "sales.gift_event_id", "sales.payment_method", "banks.card_type", "price_lists.price AS article_price", "events.event_type AS article_event_type", "gift_events.discount_amount AS store_discount_amount", "sales.gift_event_product_id").
                    order("sale_id")

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
                      else
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
                      else
                        card_payment += sale_product.subtotal
                        if sale_product.card_type.eql?("Credit")
                          total_credits += sale_product.subtotal
                        else
                          total_debits += sale_product.subtotal
                        end
                      end
                    else
                      total_quantity += 1
                      gross_sales += sale_product.article_price
                      net_sales += sale_product.subtotal
                      if sale_product.payment_method.eql?("Cash")
                        cash_payment += sale_product.subtotal
                      else
                        card_payment += sale_product.subtotal
                        if sale_product.card_type.eql?("Credit")
                          total_credits += sale_product.subtotal
                        else
                          total_debits += sale_product.subtotal
                        end
                      end
                      if sale_product.gift_event_product_id.blank? && index == sale_products.length - 1
                        net_sales -= sale_product.store_discount_amount.to_f
                        if sale_product.payment_method.eql?("Cash")
                          cash_payment -= sale_product.store_discount_amount.to_f
                        else
                          card_payment -= sale_product.store_discount_amount.to_f
                          if sale_product.card_type.eql?("Credit")
                            total_credits -= sale_product.store_discount_amount.to_f
                          else
                            total_debits -= sale_product.store_discount_amount.to_f
                          end
                        end
                      elsif sale_product.gift_event_product_id.blank? && sale_products[index + 1].sale_id != sale_product.sale_id
                        net_sales -= sale_product.store_discount_amount.to_f
                        if sale_product.payment_method.eql?("Cash")
                          cash_payment -= sale_product.store_discount_amount.to_f
                        else
                          card_payment -= sale_product.store_discount_amount.to_f
                          if sale_product.card_type.eql?("Credit")
                            total_credits -= sale_product.store_discount_amount.to_f
                          else
                            total_debits -= sale_product.store_discount_amount.to_f
                          end
                        end
                      elsif sale_product.gift_event_product_id.present? && sale_products[index + 1].sale_id != sale_product.sale_id
                        total_gift_quantity += 1
                      elsif sale_product.gift_event_product_id.present? && index == sale_products.length - 1
                        total_gift_quantity += 1
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
                  errors.add(:base, "Sorry, cashier cannot be closed") if opened_by != user_id || closed_at_was.present?
                end
    
                def set_cash_balance
                  self.cash_balance = beginning_cash
                end
    
                def today_cashier_openable
                  errors.add(:base, "Previous cashier is open, please close it first") if CashierOpening.select("1 AS one").where(warehouse_id: warehouse_id).where("closed_at IS NULL").where(["open_date <> ?", @current_date]).where("opened_by = #{opened_by}").present?
                end
    
                def second_shift_allowable      
                  first_shift = CashierOpening.select(:closed_at).where(warehouse_id: warehouse_id, station: station, shift: "1", open_date: @current_date).first
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
