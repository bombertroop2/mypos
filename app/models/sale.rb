class Sale < ApplicationRecord
  attr_accessor :warehouse_id, :cashier_id, :pay, :gift_event_gift_type,
    :gift_event_discount_amount, :attr_print_receipt, :attr_return_sale_products, :attr_total_returned
  
  belongs_to :member
  belongs_to :bank
  belongs_to :cashier_opening
  belongs_to :gift_event_product, class_name: "StockDetail", foreign_key: :gift_event_product_id
  belongs_to :gift_event, class_name: "Event", foreign_key: :gift_event_id
  belongs_to :returned_document, class_name: "SalesReturn", foreign_key: :sales_return_id
  
  has_many :sale_products, dependent: :destroy
  has_one :sales_return, dependent: :restrict_with_error
  
  PAYMENT_METHODS = [
    ["Cash", "Cash"],
    ["Card", "Card"]
  ]
  
  GIFT_OPTIONS = [
    ["Discount", "Discount"],
    ["Product", "Product"]
  ]

  accepts_nested_attributes_for :sale_products
  
  before_validation :remove_card_details, if: proc{|sale| sale.payment_method.eql?("Cash")}
    before_validation :remove_cash_details, if: proc{|sale| sale.payment_method.eql?("Card")}
      before_validation :remove_gift_event_product, if: proc{|sale| sale.gift_event_gift_type.eql?("Discount")}

        # cek record member, hanya ketika sale, retur tidak usah karena bisa jadi member dihapus
        validate :member_available, if: proc {|sale| sale.member_id.present? && !sale.attr_return_sale_products}
          validate :item_available
          validates :payment_method, presence: true, unless: proc{|sale| sale.attr_return_sale_products}
            validates :gift_event_gift_type, presence: true, if: proc{|sale| sale.gift_event_id.present?}
              validate :payment_method_available
              validate :gift_option_available, if: proc{|sale| sale.gift_event_id.present?}
                validate :is_cashier_opened, unless: proc{|sale| sale.attr_print_receipt}
                  validate :transaction_open
                  validate :transaction_after_beginning_stock_added, if: proc{|sale| Company.where(import_beginning_stock: true).select("1 AS one").present?}
                    validates :cash, presence: true, if: proc{|sale| sale.payment_method.eql?("Cash") && !sale.attr_return_sale_products}
                      validates :cash, numericality: {greater_than_or_equal_to: :sale_total}, if: proc { |sale| sale.cash.is_a?(Numeric) && sale.cash.present? && sale.payment_method.eql?("Cash") && !sale.attr_return_sale_products}
                        validates :bank_id, :trace_number, :card_number, presence: true, if: proc{|sale| sale.payment_method.eql?("Card") && !sale.attr_return_sale_products}
                          validate :bank_available, if: proc{|sale| sale.payment_method.eql?("Card") && sale.bank_id.present?}
                            validates :gift_event_discount_amount, presence: true, if: proc { |sp| sp.gift_event_gift_type.eql?("Discount") && sp.gift_event_id.present? }
                              validates :gift_event_discount_amount, numericality: {greater_than: 0}, if: proc { |sp| sp.gift_event_gift_type.eql?("Discount") && sp.gift_event_id.present? && sp.gift_event_discount_amount.present? }
                                validates :gift_event_product_id, presence: true, if: proc { |sp| sp.gift_event_gift_type.eql?("Product") && sp.gift_event_id.present? }

                                  
                                  # validasi khusus untuk sales return
                                  validates :bank_id, presence: {message: "Bank can't be blank"}, if: proc{|sale| sale.payment_method.eql?("Card") && sale.attr_return_sale_products}
                                    validates :trace_number, presence: {message: "Trace number can't be blank"}, if: proc{|sale| sale.payment_method.eql?("Card") && sale.attr_return_sale_products}
                                      validates :card_number, presence: {message: "Card number can't be blank"}, if: proc{|sale| sale.payment_method.eql?("Card") && sale.attr_return_sale_products}
                                        validates :cash, presence: {message: "Cash can't be blank"}, if: proc{|sale| sale.payment_method.eql?("Cash") && sale.attr_return_sale_products}

                                          before_create :get_total_return, :payment_method_not_blank, if: proc{|sale| sale.attr_return_sale_products}
                                            before_create :cash_not_less_than_total, if: proc{|sale| sale.payment_method.eql?("Cash") && sale.attr_return_sale_products}
                                              before_create :generate_transaction_number, :set_transaction_time, :set_cashier_opening_id
                                              before_create :set_change, if: proc{|sale| sale.payment_method.eql?("Cash")}
                                                before_create :strip_card_and_trace_number, if: proc{|sale| sale.payment_method.eql?("Card")}
                                                  after_create :update_stock, if: proc {|sale| sale.gift_event_product_id.present? && sale.gift_event_id.present? && sale.gift_event_gift_type.eql?("Product") && !sale.attr_return_sale_products}
                                                    after_create :create_listing_stock
  
                                                    private
                                                    
                                                    def get_total_return                                                      
                                                      @total_return = SalesReturn.select(:total_return).where(id: sales_return_id).first.total_return
                                                    end
                                                  
                                                    def payment_method_not_blank
                                                      total = sale_total - @total_return
                                                      if total > 0 && payment_method.strip.blank?
                                                        raise "Payment method can't be blank"
                                                      end
                                                    end
                                                        
                                                    def cash_not_less_than_total
                                                      total = sale_total - @total_return
                                                      if cash < total
                                                        raise "Cash must be greater than or equal to #{total}"
                                                      end
                                                    end
                                                                                                                          
                                                    def remove_gift_event_product
                                                      self.gift_event_product_id = nil
                                                    end
                      
                                                    def gift_option_available
                                                      GIFT_OPTIONS.select{ |x| x[1] == gift_event_gift_type }.first.first
                                                    rescue
                                                      errors.add(:gift_event_gift_type, "does not exist!") if gift_event_gift_type.present?
                                                    end

                  
                                                    def remove_card_details
                                                      self.bank_id = nil
                                                      self.trace_number = nil
                                                      self.card_number = nil
                                                    end

                                                    def remove_cash_details
                                                      self.cash = nil
                                                      self.change = nil
                                                    end
              
                                                    def strip_card_and_trace_number
                                                      self.card_number = card_number.strip
                                                      self.trace_number = trace_number.strip
                                                    end
            
                                                    def bank_available
                                                      if Bank.select("1 AS one").where(id: bank_id).blank?
                                                        unless attr_return_sale_products
                                                          errors.add(:bank_id, "does not exist!")
                                                        else
                                                          errors.add(:base, "Bank does not exist!")
                                                        end
                                                      end
                                                    end
        
                                                    def transaction_after_beginning_stock_added
                                                      listing_stock_transaction = ListingStockTransaction.select(:transaction_date).where(transaction_type: "BS").first
                                                      errors.add(:base, "Sorry, you can't perform transaction on #{Date.current.strftime("%d/%m/%Y")}") if listing_stock_transaction.transaction_date > Date.current
                                                    end
        
                                                    def transaction_open                            
                                                      errors.add(:base, "Sorry, you can't perform this transaction") if FiscalYear.joins(:fiscal_months).where(year: Date.current.year).where("fiscal_months.month = '#{Date::MONTHNAMES[Date.current.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
                                                    end
        
                                                    def set_cashier_opening_id
                                                      self.cashier_opening_id = @co.id
                                                    end
        
                                                    def is_cashier_opened
                                                      @co = CashierOpening.joins(:warehouse).select(:id, :warehouse_id).where(warehouse_id: warehouse_id).where("closed_at IS NULL").where(["open_date = ? AND warehouses.is_active = ?", Date.current, true]).where("opened_by = #{cashier_id}").first
                                                      if @co.present?
                                                        @warehouse_id = @co.warehouse_id
                                                      else
                                                        errors.add(:base, "Please open the cashier first")
                                                      end
                                                    end
      
                                                    def set_change
                                                      unless attr_return_sale_products
                                                        self.change = cash - total
                                                      else
                                                        self.change = cash - (total - @total_return)
                                                      end
                                                    end
      
                                                    def sale_total
                                                      total
                                                    end
      
                                                    def payment_method_available
                                                      PAYMENT_METHODS.select{ |x| x[1] == payment_method }.first.first
                                                    rescue
                                                      unless attr_return_sale_products
                                                        errors.add(:payment_method, "does not exist!") if payment_method.present?
                                                      else
                                                        errors.add(:base, "Payment method does not exist!") if payment_method.present?
                                                      end
                                                    end
    
                                                    def create_stock_movement(warehouse_id, product_id, color_id, size_id, transaction_date, quantity)
                                                      stock_movement = StockMovement.select(:id).where(year: transaction_date.year).first
                                                      stock_movement = StockMovement.new year: transaction_date.year if stock_movement.blank?

                                                      if stock_movement.new_record?                    
                                                        stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month
                                                        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
                                                        stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                                                        beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                        beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                        if beginning_stock.nil? || beginning_stock < 1
                                                          throw :abort
                                                        end
                                                        stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                          size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                                                        stock_movement_product_detail.stock_movement_transactions.build sold_quantity: quantity, transaction_date: transaction_date
                                                        stock_movement.save
                                                      else
                                                        stock_movement_month = stock_movement.stock_movement_months.select(:id).where(month: transaction_date.month).first
                                                        stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month if stock_movement_month.blank?
                                                        if stock_movement_month.new_record?                      
                                                          stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
                                                          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                                                          beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                          beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                          if beginning_stock.nil? || beginning_stock < 1
                                                            throw :abort
                                                          end
                                                          stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                            size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                                                          stock_movement_product_detail.stock_movement_transactions.build sold_quantity: quantity, transaction_date: transaction_date
                                                          stock_movement_month.save
                                                        else
                                                          stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select(:id).where(warehouse_id: warehouse_id).first
                                                          stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id if stock_movement_warehouse.blank?
                                                          if stock_movement_warehouse.new_record?                        
                                                            stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                                                            beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                            beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                            if beginning_stock.nil? || beginning_stock < 1
                                                              throw :abort
                                                            end
                                                            stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                              size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                                                            stock_movement_product_detail.stock_movement_transactions.build sold_quantity: quantity, transaction_date: transaction_date
                                                            stock_movement_warehouse.save
                                                          else
                                                            stock_movement_product = stock_movement_warehouse.stock_movement_products.select(:id).where(product_id: product_id).first
                                                            stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id if stock_movement_product.blank?
                                                            if stock_movement_product.new_record?                          
                                                              beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                              beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                              if beginning_stock.nil? || beginning_stock < 1
                                                                throw :abort
                                                              end
                                                              stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                                size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                                                              stock_movement_product_detail.stock_movement_transactions.build sold_quantity: quantity, transaction_date: transaction_date
                                                              stock_movement_product.save
                                                            else
                                                              stock_movement_product_detail = stock_movement_product.stock_movement_product_details.select(:id, :ending_stock).
                                                                where(color_id: color_id, size_id: size_id).first
                                                              if stock_movement_product_detail.blank?
                                                                beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                                beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                                if beginning_stock.nil? || beginning_stock < 1
                                                                  throw :abort
                                                                end
                                                                stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                                  size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                                                                stock_movement_product_detail.stock_movement_transactions.build sold_quantity: quantity, transaction_date: transaction_date
                                                                stock_movement_product_detail.save
                                                              else
                                                                stock_movement_product_detail.with_lock do
                                                                  stock_movement_product_detail.ending_stock -= quantity
                                                                  stock_movement_product_detail.stock_movement_transactions.build sold_quantity: quantity, transaction_date: transaction_date
                                                                  stock_movement_product_detail.save
                                                                end
                                                              end
                                                            end
                                                          end
                                                        end
                                                      end
                                                    end
    
                                                    def create_listing_stock
                                                      sale_products.joins(product_barcode: :product_color).joins("LEFT JOIN events ON sale_products.event_id = events.id").joins("LEFT JOIN stock_details ON sale_products.free_product_id = stock_details.id").select("sale_products.total, product_id, product_colors.color_id, product_barcodes.size_id, sale_products.quantity, events.event_type AS product_event_type, stock_details.size_id AS free_product_size_id, stock_details.color_id AS free_product_color_id, free_product_id").each do |sale_product|
                                                        # listing stock untuk item yang dibeli
                                                        listing_stock = ListingStock.select(:id).where(warehouse_id: @warehouse_id, product_id: sale_product.product_id).first
                                                        listing_stock = ListingStock.new warehouse_id: @warehouse_id, product_id: sale_product.product_id if listing_stock.blank?
                                                        if listing_stock.new_record?                    
                                                          listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: sale_product.color_id, size_id: sale_product.size_id
                                                          listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_time.to_date, transaction_number: transaction_number, transaction_type: "POS", transactionable_id: self.id, transactionable_type: self.class.name, quantity: sale_product.quantity
                                                          listing_stock.save
                                                        else
                                                          listing_stock_product_detail = listing_stock.listing_stock_product_details.where(color_id: sale_product.color_id, size_id: sale_product.size_id).select(:id).first
                                                          listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: sale_product.color_id, size_id: sale_product.size_id if listing_stock_product_detail.blank?
                                                          if listing_stock_product_detail.new_record?
                                                            listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_time.to_date, transaction_number: transaction_number, transaction_type: "POS", transactionable_id: self.id, transactionable_type: self.class.name, quantity: sale_product.quantity
                                                            listing_stock_product_detail.save
                                                          else
                                                            listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.where(transaction_date: transaction_time.to_date, transaction_number: transaction_number, transaction_type: "POS", transactionable_id: self.id, transactionable_type: self.class.name).select(:id, :quantity).first
                                                            if listing_stock_transaction.present?
                                                              listing_stock_transaction.with_lock do
                                                                listing_stock_transaction.quantity += sale_product.quantity
                                                                listing_stock_transaction.save
                                                              end
                                                            else
                                                              listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_time.to_date, transaction_number: transaction_number, transaction_type: "POS", transactionable_id: self.id, transactionable_type: self.class.name, quantity: sale_product.quantity
                                                              listing_stock_transaction.save
                                                            end
                                                          end
                                                        end
                                                        create_stock_movement(@warehouse_id, sale_product.product_id, sale_product.color_id, sale_product.size_id, transaction_time.to_date, sale_product.quantity)


                                                        # listing stock untuk free item (event BOGO) apabila ada
                                                        if sale_product.product_event_type.eql?("Buy 1 Get 1 Free") && sale_product.free_product_color_id.present? && sale_product.free_product_size_id.present?
                                                          product_id = StockDetail.joins(:stock_product).select(:product_id).where(id: sale_product.free_product_id).first.product_id
                                                          listing_stock = ListingStock.select(:id).where(warehouse_id: @warehouse_id, product_id: product_id).first
                                                          listing_stock = ListingStock.new warehouse_id: @warehouse_id, product_id: product_id if listing_stock.blank?
                                                          if listing_stock.new_record?                    
                                                            listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: sale_product.free_product_color_id, size_id: sale_product.free_product_size_id
                                                            listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_time.to_date, transaction_number: transaction_number, transaction_type: "POS", transactionable_id: self.id, transactionable_type: self.class.name, quantity: sale_product.quantity
                                                            listing_stock.save
                                                          else
                                                            listing_stock_product_detail = listing_stock.listing_stock_product_details.where(color_id: sale_product.free_product_color_id, size_id: sale_product.free_product_size_id).select(:id).first
                                                            listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: sale_product.free_product_color_id, size_id: sale_product.free_product_size_id if listing_stock_product_detail.blank?
                                                            if listing_stock_product_detail.new_record?
                                                              listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_time.to_date, transaction_number: transaction_number, transaction_type: "POS", transactionable_id: self.id, transactionable_type: self.class.name, quantity: sale_product.quantity
                                                              listing_stock_product_detail.save
                                                            else
                                                              listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.where(transaction_date: transaction_time.to_date, transaction_number: transaction_number, transaction_type: "POS", transactionable_id: self.id, transactionable_type: self.class.name).select(:id, :quantity).first
                                                              if listing_stock_transaction.present?
                                                                listing_stock_transaction.with_lock do
                                                                  listing_stock_transaction.quantity += sale_product.quantity
                                                                  listing_stock_transaction.save
                                                                end
                                                              else
                                                                listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_time.to_date, transaction_number: transaction_number, transaction_type: "POS", transactionable_id: self.id, transactionable_type: self.class.name, quantity: sale_product.quantity
                                                                listing_stock_transaction.save
                                                              end
                                                            end
                                                          end
                                                          create_stock_movement(@warehouse_id, product_id, sale_product.free_product_color_id, sale_product.free_product_size_id, transaction_time.to_date, sale_product.quantity)
                                                        end 
                                                      end 
                                    
                                                      # listing stock untuk produk gift event apabila ada
                                                      if gift_event_product_id.present? && gift_event_id.present? && gift_event_gift_type.eql?("Product")
                                                        product_id = @gift_product_id
                                                        color_id = @gift_color_id
                                                        size_id = @gift_size_id
                                                        listing_stock = ListingStock.select(:id).where(warehouse_id: @warehouse_id, product_id: product_id).first
                                                        listing_stock = ListingStock.new warehouse_id: @warehouse_id, product_id: product_id if listing_stock.blank?
                                                        if listing_stock.new_record?                    
                                                          listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id
                                                          listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_time.to_date, transaction_number: transaction_number, transaction_type: "POS", transactionable_id: self.id, transactionable_type: self.class.name, quantity: 1
                                                          listing_stock.save
                                                        else
                                                          listing_stock_product_detail = listing_stock.listing_stock_product_details.where(color_id: color_id, size_id: size_id).select(:id).first
                                                          listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id if listing_stock_product_detail.blank?
                                                          if listing_stock_product_detail.new_record?
                                                            listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_time.to_date, transaction_number: transaction_number, transaction_type: "POS", transactionable_id: self.id, transactionable_type: self.class.name, quantity: 1
                                                            listing_stock_product_detail.save
                                                          else
                                                            listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.where(transaction_date: transaction_time.to_date, transaction_number: transaction_number, transaction_type: "POS", transactionable_id: self.id, transactionable_type: self.class.name).select(:id, :quantity).first
                                                            if listing_stock_transaction.present?
                                                              listing_stock_transaction.with_lock do
                                                                listing_stock_transaction.quantity += 1
                                                                listing_stock_transaction.save
                                                              end
                                                            else
                                                              listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_time.to_date, transaction_number: transaction_number, transaction_type: "POS", transactionable_id: self.id, transactionable_type: self.class.name, quantity: 1
                                                              listing_stock_transaction.save
                                                            end
                                                          end
                                                        end
                                                        create_stock_movement(@warehouse_id, product_id, color_id, size_id, transaction_time.to_date, 1)
                                                      end
                                                    end
    
                                                    def set_transaction_time
                                                      self.transaction_time = Time.current
                                                    end
    
                                                    def generate_transaction_number
                                                      warehouse = Warehouse.select(:id, :code).where(id: @warehouse_id).first
                                                      warehouse_code = warehouse.code.split("-")[0]
                                                      last_transaction = warehouse.sales.select(:transaction_number).last
                                                      if last_transaction.nil?
                                                        new_number = "#{warehouse_code}0000000001"
                                                      else
                                                        seq_number = last_transaction.transaction_number.split("#{warehouse_code}").last
                                                        new_number = "#{warehouse_code}#{seq_number.succ}"
                                                      end
                                                      self.transaction_number = new_number
                                                    end
  
                                                    def member_available
                                                      errors.add(:base, "Members not found") if Member.select("1 AS one").where(id: member_id).blank?
                                                    end
    
                                                    def item_available
                                                      errors.add(:base, "Please insert at least one product per transaction!") if sale_products.blank?
                                                    end
                                  
                                                    # update stock apabila ada barang yang keluar untuk GIFT event
                                                    def update_stock
                                                      stock_detail = StockDetail.joins(:stock_product).where(id: gift_event_product_id).select(:id, :color_id, :size_id, :quantity, :booked_quantity).select("stock_products.product_id").first
                                                      @gift_product_id = stock_detail.product_id
                                                      @gift_color_id = stock_detail.color_id
                                                      @gift_size_id = stock_detail.size_id
                                                      raise_error = false
                                                      stock_detail.with_lock do
                                                        if stock_detail.quantity.to_i - stock_detail.booked_quantity.to_i >= 1
                                                          stock_detail.quantity -= 1
                                                          stock_detail.save
                                                        else
                                                          raise_error = true
                                                        end
                                                      end          
                                                      if raise_error
                                                        raise "Sorry, selected gift item is temporarily out of stock"
                                                      end
                                                    end
                                                  end
