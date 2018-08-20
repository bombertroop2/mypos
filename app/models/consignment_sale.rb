class ConsignmentSale < ApplicationRecord
  attr_accessor :attr_warehouse_code, :attr_delete_by_admin,
    :attr_spg_warehouse_id, :attr_am_warehouse_ids, :attr_supervisor_id,
    :attr_create_by_am, :attr_delete_products, :attr_importing_data
  audited on: [:create, :update]
  has_many :consignment_sale_products, dependent: :destroy
  has_many :listing_stock_transactions, as: :transactionable
  belongs_to :warehouse

  validate :product_is_exist, on: :create, if: proc{|cs| !cs.no_sale && !cs.attr_importing_data}
    validate :transaction_date_is_valid, :transaction_date_not_blank, on: :create
    validate :warehouse_not_blank, :warehouse_is_counter, on: :create
    validate :record_not_approved, :record_not_unapproved, on: :update
    validate :transaction_open, unless: proc{|cs| cs.attr_importing_data}
      validate :transaction_after_beginning_stock_added, if: proc{|sale| !sale.attr_delete_products && !sale.attr_importing_data && Company.where(import_beginning_stock: true).select("1 AS one").present?}
        validate :record_not_updated, :record_belongs_to_me, if: proc{|cs| cs.attr_delete_products}, on: :update

          before_create :delete_counter_event_id, :sale_not_created
          before_create :generate_number, unless: proc{|cs| cs.attr_importing_data}
            before_create :yesterday_transaction_exist
            before_destroy :record_not_deleted, :delete_tracks
            after_update :update_stock_and_afs, unless: proc{|cs| cs.attr_delete_products}
              after_update :create_listing_stock, if: proc{|cs| !cs.approved_was && cs.approved && !cs.attr_delete_products}
                after_update :delete_listing_stock, :delete_stock_movement, if: proc{|cs| cs.approved_was && !cs.approved && !cs.attr_delete_products}

                  accepts_nested_attributes_for :consignment_sale_products, allow_destroy: true, reject_if: proc { |attributes| attributes[:attr_no_sale].eql?("true") }

                  private

                  def sale_not_created
                    if no_sale
                      if ConsignmentSale.select("1 AS one").where(["warehouse_id = ? AND transaction_date = ?", warehouse_id, transaction_date]).present?
                        raise "Sorry, you can't create a transaction on #{transaction_date.strftime("%d/%m/%Y")}"
                      end
                    else
                      if ConsignmentSale.select("1 AS one").where(["transaction_date = ? AND no_sale = ? AND warehouse_id = ?", transaction_date, true, warehouse_id]).present?
                        raise "Sorry, you can't create a transaction on #{transaction_date.strftime("%d/%m/%Y")}"
                      end
                    end
                  end

                  def delete_counter_event_id
                    self.counter_event_id = nil if no_sale
                  end

                  def yesterday_transaction_exist
                    consignment_sales = ConsignmentSale.
                      where(["warehouse_id = ?", warehouse_id]).
                      select(:transaction_date)
                    if consignment_sales.present?
                      raise "Please create a transaction before #{transaction_date.strftime("%d/%m/%Y")} first" if consignment_sales.select{|cs| cs.transaction_date == transaction_date - 1}.blank? && consignment_sales.select{|cs| cs.transaction_date == transaction_date}.blank?
                    end
                  end

                  def record_belongs_to_me
                    if attr_spg_warehouse_id.present?
                      if ConsignmentSale.select("1 AS one").where(id: id, warehouse_id: attr_spg_warehouse_id).blank?
                        errors.add(:base, "The record cannot be edited")
                      end
                    elsif attr_am_warehouse_ids.present?
                      if ConsignmentSale.select("1 AS one").where(id: id, warehouse_id: attr_am_warehouse_ids).blank?
                        errors.add(:base, "The record cannot be edited")
                      end
                    end
                  end

                  def record_not_updated
                    errors.add(:base, "The record cannot be edited") if approved
                  end

                  def transaction_after_beginning_stock_added
                    listing_stock_transaction = ListingStockTransaction.select(:transaction_date).where(transaction_type: "BS").first
                    errors.add(:base, "Sorry, you can't perform transaction on #{transaction_date.strftime("%d/%m/%Y")}") if listing_stock_transaction.transaction_date > transaction_date
                  end

                  def transaction_open
                    errors.add(:base, "Sorry, you can't perform this transaction") if FiscalYear.joins(:fiscal_months).where(year: transaction_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[transaction_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
                  end

                  def create_listing_stock
                    consignment_sale_products.joins(product_barcode: :product_color).select("product_colors.product_id, product_colors.color_id, product_barcodes.size_id").each do |consignment_sale_product|
                      # listing stock untuk item yang dibeli
                      listing_stock = ListingStock.select(:id).where(warehouse_id: warehouse_id, product_id: consignment_sale_product.product_id).first
                      listing_stock = ListingStock.new warehouse_id: warehouse_id, product_id: consignment_sale_product.product_id if listing_stock.blank?
                      if listing_stock.new_record?
                        listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: consignment_sale_product.color_id, size_id: consignment_sale_product.size_id
                        listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: transaction_number, transaction_type: "SLK", transactionable_id: self.id, transactionable_type: self.class.name, quantity: 1
                        listing_stock.save
                      else
                        listing_stock_product_detail = listing_stock.listing_stock_product_details.where(color_id: consignment_sale_product.color_id, size_id: consignment_sale_product.size_id).select(:id).first
                        listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: consignment_sale_product.color_id, size_id: consignment_sale_product.size_id if listing_stock_product_detail.blank?
                        if listing_stock_product_detail.new_record?
                          listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: transaction_number, transaction_type: "SLK", transactionable_id: self.id, transactionable_type: self.class.name, quantity: 1
                          listing_stock_product_detail.save
                        else
                          listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.where(transaction_date: transaction_date, transaction_number: transaction_number, transaction_type: "SLK", transactionable_id: self.id, transactionable_type: self.class.name).select(:id, :quantity).first
                          if listing_stock_transaction.present?
                            listing_stock_transaction.with_lock do
                              listing_stock_transaction.quantity += 1
                              listing_stock_transaction.save
                            end
                          else
                            listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: transaction_number, transaction_type: "SLK", transactionable_id: self.id, transactionable_type: self.class.name, quantity: 1
                            listing_stock_transaction.save
                          end
                        end
                      end
                      create_stock_movement(warehouse_id, consignment_sale_product.product_id, consignment_sale_product.color_id, consignment_sale_product.size_id, transaction_date, 1)
                    end
                  end

                  def delete_listing_stock
                    listing_stock_transactions.destroy_all
                  end

                  def update_stock_and_afs
                    if approved_was && !approved
                      consignment_sale_products.select(:id, :product_barcode_id).each do |consignment_sale_product|
                        sd = if attr_supervisor_id.present?
                          StockDetail.joins(stock_product: [product: [product_colors: :product_barcodes], stock: :warehouse]).
                            where(:"product_barcodes.id" => consignment_sale_product.product_barcode_id, :"warehouses.is_active" => true, :"warehouses.supervisor_id" => attr_supervisor_id).
                            where(["stocks.warehouse_id = ?", warehouse_id]).
                            where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
                            select(:id, :unapproved_quantity, :quantity).first
                        else
                          if attr_spg_warehouse_id != warehouse_id
                            StockDetail.none.first
                          else
                            StockDetail.joins(stock_product: [product: [product_colors: :product_barcodes], stock: :warehouse]).
                              where(:"product_barcodes.id" => consignment_sale_product.product_barcode_id, :"warehouses.is_active" => true).
                              where(["stocks.warehouse_id = ?", warehouse_id]).
                              where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
                              select(:id, :unapproved_quantity, :quantity).first
                          end
                        end
                        if sd.present?
                          sd.with_lock do
                            sd.unapproved_quantity += 1
                            sd.quantity += 1
                            sd.save
                          end
                        else
                          raise "Something went wrong. Please try again"
                        end
                      end
                    elsif !approved_was && approved
                      consignment_sale_products.select(:id, :product_barcode_id).each do |consignment_sale_product|
                        sd = if attr_supervisor_id.present?
                          StockDetail.joins(stock_product: [product: [product_colors: :product_barcodes], stock: :warehouse]).
                            where(:"product_barcodes.id" => consignment_sale_product.product_barcode_id, :"warehouses.is_active" => true, :"warehouses.supervisor_id" => attr_supervisor_id).
                            where(["stocks.warehouse_id = ?", warehouse_id]).
                            where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
                            select(:id, :unapproved_quantity, :quantity).first
                        else
                          if attr_spg_warehouse_id != warehouse_id
                            StockDetail.none.first
                          else
                            StockDetail.joins(stock_product: [product: [product_colors: :product_barcodes], stock: :warehouse]).
                              where(:"product_barcodes.id" => consignment_sale_product.product_barcode_id, :"warehouses.is_active" => true).
                              where(["stocks.warehouse_id = ?", warehouse_id]).
                              where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
                              select(:id, :unapproved_quantity, :quantity).first
                          end
                        end
                        if sd.present?
                          raise_error = false
                          sd.with_lock do
                            if sd.unapproved_quantity < 1 || sd.quantity < 1
                              raise_error = true
                            else
                              sd.unapproved_quantity -= 1
                              sd.quantity -= 1
                              sd.save
                            end
                          end
                          raise "Something went wrong. Please try again" if raise_error
                        else
                          raise "Something went wrong. Please try again"
                        end
                      end
                    end
                  end

                  def record_not_unapproved
                    errors.add(:base, "Sorry, transaction #{transaction_number} is already unapproved") if !approved_was && !approved && !attr_delete_products
                  end

                  def record_not_approved
                    errors.add(:base, "Sorry, transaction #{transaction_number} is already approved") if approved_was && approved && !attr_delete_products
                  end

                  def warehouse_is_counter
                    if attr_create_by_am
                      errors.add(:base, "Warehouse does not exist!") if warehouse_id.present? && Warehouse.select("1 AS one").counter.where(id: warehouse_id, supervisor_id: attr_supervisor_id).blank?
                    else
                      errors.add(:base, "Warehouse does not exist!") if warehouse_id.present? && Warehouse.select("1 AS one").counter.where(id: warehouse_id).blank?
                    end
                  end

                  def record_not_deleted
                    if attr_delete_by_admin
                      raise "Sorry, you can't delete a record" if approved
                    else
                      # apabila deleting oleh area manager
                      if attr_am_warehouse_ids.present?
                        raise "Sorry, you can't delete a record" if approved || ConsignmentSale.select("1 AS one").where(id: id, warehouse_id: attr_am_warehouse_ids).blank?
                      else
                        raise "Sorry, you can't delete a record" if approved || ConsignmentSale.select("1 AS one").where(id: id, warehouse_id: attr_spg_warehouse_id).blank?
                      end
                    end
                  end

                  def product_is_exist
                    errors.add(:base, "Please insert at least one product per transaction!") if consignment_sale_products.blank? && !no_sale
                  end

                  def transaction_date_not_blank
                    if transaction_date.blank?
                      errors.add(:base, "Transaction date can't be blank")
                    end
                  end

                  def warehouse_not_blank
                    if warehouse_id.blank?
                      errors.add(:base, "Warehouse can't be blank")
                    end
                  end

                  def transaction_date_is_valid
                    if transaction_date.present? && transaction_date > Date.current
                      errors.add(:base, "Transaction date must be before or equal to today")
                    end
                  end

                  def delete_tracks
                    audits.destroy_all
                  end

                  def generate_number
                    today = transaction_date
                    current_month = today.month.to_s.rjust(2, '0')
                    current_year = today.strftime("%y").rjust(2, '0')
                    existed_numbers = unless no_sale
                      ConsignmentSale.where(["warehouse_id = ?", warehouse_id]).where("transaction_number LIKE '1S#{attr_warehouse_code}#{current_month}#{current_year}%'").select(:transaction_number).order(:transaction_number)
                    else
                      ConsignmentSale.where(["warehouse_id = ?", warehouse_id]).where("transaction_number LIKE '1SNOSALE#{current_month}#{current_year}%'").select(:transaction_number).order(:transaction_number)
                    end
                    if existed_numbers.blank?
                      new_number = unless no_sale
                        "1S#{attr_warehouse_code}#{current_month}#{current_year}0000001"
                      else
                        "1SNOSALE#{current_month}#{current_year}001"
                      end
                    else
                      if existed_numbers.length == 1
                        seq_number = unless no_sale
                          existed_numbers[0].transaction_number.split("1S#{attr_warehouse_code}#{current_month}#{current_year}").last
                        else
                          existed_numbers[0].transaction_number.split("1SNOSALE#{current_month}#{current_year}").last
                        end
                        if seq_number.to_i > 1
                          new_number = unless no_sale
                            "1S#{attr_warehouse_code}#{current_month}#{current_year}0000001"
                          else
                            "1SNOSALE#{current_month}#{current_year}001"
                          end
                        else
                          new_number = unless no_sale
                            "1S#{attr_warehouse_code}#{current_month}#{current_year}#{seq_number.succ}"
                          else
                            "1SNOSALE#{current_month}#{current_year}#{seq_number.succ}"
                          end
                        end
                      else
                        last_seq_number = ""
                        existed_numbers.each_with_index do |existed_number, index|
                          seq_number = unless no_sale
                            existed_number.transaction_number.split("1S#{attr_warehouse_code}#{current_month}#{current_year}").last
                          else
                            existed_number.transaction_number.split("1SNOSALE#{current_month}#{current_year}").last
                          end
                          if seq_number.to_i > 1 && index == 0
                            new_number = unless no_sale
                              "1S#{attr_warehouse_code}#{current_month}#{current_year}0000001"
                            else
                              "1SNOSALE#{current_month}#{current_year}001"
                            end
                            break
                          elsif last_seq_number.eql?("")
                            last_seq_number = seq_number
                          elsif (seq_number.to_i - last_seq_number.to_i) > 1
                            new_number = unless no_sale
                              "1S#{attr_warehouse_code}#{current_month}#{current_year}#{last_seq_number.succ}"
                            else
                              "1SNOSALE#{current_month}#{current_year}#{last_seq_number.succ}"
                            end
                            break
                          elsif index == existed_numbers.length - 1
                            new_number = unless no_sale
                              "1S#{attr_warehouse_code}#{current_month}#{current_year}#{seq_number.succ}"
                            else
                              "1SNOSALE#{current_month}#{current_year}#{seq_number.succ}"
                            end
                          else
                            last_seq_number = seq_number
                          end
                        end
                      end
                    end
                    self.transaction_number = new_number
                  end

                  def create_stock_movement(warehouse_id, product_id, color_id, size_id, transaction_date, quantity)
                    next_month_movements = StockMovementProductDetail.
                      joins(:stock_movement_transactions,
                      stock_movement_product: :stock_movement_warehouse).
                      select(:id, :beginning_stock, :ending_stock).
                      where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date >= ?", warehouse_id, product_id, color_id, size_id, transaction_date.next_month.beginning_of_month]).
                      group(:id, :beginning_stock, :ending_stock)
                    next_month_movements.each do |next_month_movement|
                      next_month_movement.with_lock do
                        next_month_movement.beginning_stock -= quantity
                        next_month_movement.ending_stock -= quantity
                        next_month_movement.save
                      end
                    end
                    stock_movement = StockMovement.select(:id).where(year: transaction_date.year).first
                    stock_movement = StockMovement.new year: transaction_date.year if stock_movement.blank?
                    if stock_movement.new_record?
                      stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month
                      stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
                      stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                      beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                      beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                      if beginning_stock.nil? || (beginning_stock.present? && beginning_stock < 1)
                        throw :abort
                      end
                      stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                        size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                      stock_movement_product_detail.stock_movement_transactions.build consignment_sold_quantity: quantity, transaction_date: transaction_date
                      stock_movement.save
                    else
                      stock_movement_month = stock_movement.stock_movement_months.select(:id).where(month: transaction_date.month).first
                      stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month if stock_movement_month.blank?
                      if stock_movement_month.new_record?
                        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
                        stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                        beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                        beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                        if beginning_stock.nil? || (beginning_stock.present? && beginning_stock < 1)
                          throw :abort
                        end
                        stock_movement_product_detail = stock_movement_product.
                          stock_movement_product_details.build color_id: color_id,
                          size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                        stock_movement_product_detail.stock_movement_transactions.build consignment_sold_quantity: quantity, transaction_date: transaction_date
                        stock_movement_month.save
                      else
                        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select(:id).where(warehouse_id: warehouse_id).first
                        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id if stock_movement_warehouse.blank?
                        if stock_movement_warehouse.new_record?
                          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                          beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                          beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                          if beginning_stock.nil? || (beginning_stock.present? && beginning_stock < 1)
                            throw :abort
                          end
                          stock_movement_product_detail = stock_movement_product.
                            stock_movement_product_details.build color_id: color_id,
                            size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                          stock_movement_product_detail.stock_movement_transactions.build consignment_sold_quantity: quantity, transaction_date: transaction_date
                          stock_movement_warehouse.save
                        else
                          stock_movement_product = stock_movement_warehouse.stock_movement_products.select(:id).where(product_id: product_id).first
                          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id if stock_movement_product.blank?
                          if stock_movement_product.new_record?
                            beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                            beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                            if beginning_stock.nil? || (beginning_stock.present? && beginning_stock < 1)
                              throw :abort
                            end
                            stock_movement_product_detail = stock_movement_product.
                              stock_movement_product_details.build color_id: color_id,
                              size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                            stock_movement_product_detail.stock_movement_transactions.build consignment_sold_quantity: quantity, transaction_date: transaction_date
                            stock_movement_product.save
                          else
                            stock_movement_product_detail = stock_movement_product.stock_movement_product_details.select(:id, :ending_stock).
                              where(color_id: color_id, size_id: size_id).first
                            if stock_movement_product_detail.blank?
                              beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                              beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                              if beginning_stock.nil? || (beginning_stock.present? && beginning_stock < 1)
                                throw :abort
                              end
                              stock_movement_product_detail = stock_movement_product.
                                stock_movement_product_details.build color_id: color_id,
                                size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                              stock_movement_product_detail.stock_movement_transactions.build consignment_sold_quantity: quantity, transaction_date: transaction_date
                              stock_movement_product_detail.save
                            else
                              stock_movement_product_detail.with_lock do
                                stock_movement_product_detail.ending_stock -= quantity
                                stock_movement_product_detail.stock_movement_transactions.build consignment_sold_quantity: quantity, transaction_date: transaction_date
                                stock_movement_product_detail.save
                              end
                            end
                          end
                        end
                      end
                    end
                  end

                  def delete_stock_movement
                    consignment_sale_products.joins(product_barcode: :product_color).select("product_colors.product_id, product_colors.color_id, product_barcodes.size_id").each do |consignment_sale_product|
                      created_movement = StockMovementTransaction.joins(stock_movement_product_detail: [stock_movement_product: [stock_movement_warehouse: [stock_movement_month: :stock_movement]]]).where(["stock_movement_products.product_id = ? AND stock_movement_product_details.color_id = ? AND stock_movement_product_details.size_id = ? AND stock_movement_warehouses.warehouse_id = ? AND transaction_date = ? AND consignment_sold_quantity = ?", consignment_sale_product.product_id, consignment_sale_product.color_id, consignment_sale_product.size_id, warehouse_id, transaction_date, 1]).select(:id, :stock_movement_product_detail_id).first
                      if created_movement
                        stock_movement_product_detail_deleted = false
                        stock_movement_product_details = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:id, :beginning_stock, :ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date >= ?", warehouse_id, consignment_sale_product.product_id, consignment_sale_product.color_id, consignment_sale_product.size_id, transaction_date.beginning_of_month]).group(:id, :beginning_stock, :ending_stock)
                        stock_movement_product_details.each do |stock_movement_product_detail|
                          stock_movement_product_detail.with_lock do
                            if created_movement.stock_movement_product_detail_id == stock_movement_product_detail.id
                              if stock_movement_product_detail.stock_movement_transactions.count(:id) == 1
                                stock_movement_product_detail_deleted = stock_movement_product_detail.destroy
                              else
                                stock_movement_product_detail.ending_stock += 1
                              end
                            else
                              stock_movement_product_detail.beginning_stock += 1
                              stock_movement_product_detail.ending_stock += 1
                            end
                            stock_movement_product_detail.save
                          end
                        end
                        created_movement.destroy unless stock_movement_product_detail_deleted
                      end
                    end
                  end

                end
