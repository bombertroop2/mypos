class StockMutation < ApplicationRecord
  attr_accessor :mutation_type, :approving_mutation, :receiving_inventory_to_store, :receiving_inventory_to_warehouse
  
  audited on: [:create, :update]
  has_associated_audits

  belongs_to :courier
  belongs_to :origin_warehouse, class_name: "Warehouse", foreign_key: :origin_warehouse_id
  belongs_to :destination_warehouse, class_name: "Warehouse", foreign_key: :destination_warehouse_id
  has_many :stock_mutation_products, dependent: :destroy

  accepts_nested_attributes_for :stock_mutation_products

  validates :delivery_date, :courier_id, :origin_warehouse_id, :destination_warehouse_id, presence: true
  validates :delivery_date, date: {after_or_equal_to: proc { Date.current }, message: 'must be after or equal to today' }, if: proc {|shpmnt| shpmnt.delivery_date.present? && !shpmnt.receiving_inventory_to_store && !shpmnt.receiving_inventory_to_warehouse}
    validate :courier_available, :origin_warehouse_available
    validate :destination_warehouse_available, unless: proc {|sm| sm.receiving_inventory_to_warehouse}
    validate :editable, on: :update, if: proc{|sm| !sm.approving_mutation && !sm.receiving_inventory_to_store && !sm.receiving_inventory_to_warehouse}
      validate :approvable, if: proc{|sm| sm.approving_mutation}
        validates :received_date, presence: true, if: proc{|sm| sm.receiving_inventory_to_store || sm.receiving_inventory_to_warehouse}
          validates :received_date, date: {before_or_equal_to: Proc.new { Date.current }, message: 'must be before or equal to today' }, if: proc {|sm| sm.received_date.present? && (sm.receiving_inventory_to_store || sm.receiving_inventory_to_warehouse)}
            validates :received_date, date: {after_or_equal_to: proc {|sm| sm.approved_date}, message: 'must be after or equal to approved date' }, if: proc {|sm| sm.received_date.present? && sm.receiving_inventory_to_store}
            validates :received_date, date: {after_or_equal_to: proc {|sm| sm.delivery_date}, message: 'must be after or equal to delivery date' }, if: proc {|sm| sm.received_date.present? && sm.receiving_inventory_to_warehouse}
              validate :shipment_receivable, if: proc{|sm| sm.receiving_inventory_to_store || sm.receiving_inventory_to_warehouse}

                before_create :generate_number
                before_destroy :prevent_delete_if_mutation_approved, :delete_tracks
                before_update :apologize_to_previous_destination_store, if: proc{|sm| !sm.destination_warehouse.warehouse_type.eql?("central") && sm.destination_warehouse_id_changed?}
                  after_create :notify_origin_store, :notify_destination_store, unless: proc {|sm| sm.destination_warehouse.warehouse_type.eql?("central")}
                    after_create :notify_warehouse, if: proc {|sm| sm.destination_warehouse.warehouse_type.eql?("central")}
                      after_update :notify_new_warehouse, if: proc {|sm| sm.destination_warehouse.warehouse_type.eql?("central") && sm.destination_warehouse_id_changed?}
                        after_update :notify_new_destination_store, if: proc {|sm| !sm.destination_warehouse.warehouse_type.eql?("central") && sm.destination_warehouse_id_changed?}
                          after_update :update_stock, if: proc {|sm| sm.approving_mutation}
                            after_update :load_goods_to_destination_warehouse, if: proc{|sm| sm.receiving_inventory_to_store || sm.receiving_inventory_to_warehouse}

                              private
                              
                              def load_goods_to_destination_warehouse
                                stock = Stock.new warehouse_id: destination_warehouse_id
                                stock_mutation_products.select(:id, :product_id).each do |stock_mutation_product|
                                  product_id = stock_mutation_product.product_id
                                  stock_product = stock.stock_products.build product_id: product_id
                                  stock_mutation_product.stock_mutation_product_items.select(:size_id, :color_id, :quantity).each do |stock_mutation_product_item|
                                    if stock_mutation_product_item.quantity > 0
                                      size_id = stock_mutation_product_item.size_id
                                      color_id = stock_mutation_product_item.color_id
                                      stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: stock_mutation_product_item.quantity
                                    end
                                  end
                                end
                                begin
                                  stock.save
                                rescue ActiveRecord::RecordNotUnique => e
                                  stock = destination_warehouse.stock
                                  stock_mutation_products.select(:id, :product_id).each do |stock_mutation_product|
                                    product_id = stock_mutation_product.product_id
                                    stock_product = stock.stock_products.build product_id: product_id
                                    stock_mutation_product.stock_mutation_product_items.select(:size_id, :color_id, :quantity).each do |stock_mutation_product_item|
                                      if stock_mutation_product_item.quantity > 0
                                        size_id = stock_mutation_product_item.size_id
                                        color_id = stock_mutation_product_item.color_id
                                        stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: stock_mutation_product_item.quantity
                                      end
                                    end
                                    begin
                                      stock_product.save
                                    rescue ActiveRecord::RecordNotUnique => e
                                      stock_product = stock.stock_products.select{|sp| sp.product_id.eql?(product_id)}.first
                                      stock_mutation_product.stock_mutation_product_items.select(:size_id, :color_id, :quantity).each do |stock_mutation_product_item|
                                        if stock_mutation_product_item.quantity > 0
                                          size_id = stock_mutation_product_item.size_id
                                          color_id = stock_mutation_product_item.color_id
                                          stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: stock_mutation_product_item.quantity
                                          begin
                                            stock_detail.save
                                          rescue ActiveRecord::RecordNotUnique => e
                                            stock_detail = stock_product.stock_details.select{|sd| sd.size_id.eql?(size_id) && sd.color_id.eql?(color_id)}.first
                                            stock_detail.with_lock do
                                              stock_detail.quantity += stock_mutation_product_item.quantity
                                              stock_detail.save
                                            end
                                          end
                                        end
                                      end
                                    end
                                  end
                                end                        
                              end
                            
                              def shipment_receivable
                                errors.add(:base, "Sorry, inventory #{number} is already received") if received_date_was.present?
                              end
                  
                              def update_stock
                                raise_error = false
                                stock_mutation_products.select(:id, :product_id).each do |stock_mutation_product|
                                  stock_mutation_product.stock_mutation_product_items.select(:quantity, :size_id, :color_id).each do |stock_mutation_product_item|
                                    stock = StockDetail.joins(stock_product: :stock).
                                      where(["warehouse_id = ? AND size_id = ? AND color_id = ? AND stock_products.product_id = ?", origin_warehouse_id, stock_mutation_product_item.size_id, stock_mutation_product_item.color_id, stock_mutation_product.product_id]).
                                      select(:id, :quantity).first
                                    stock.with_lock do
                                      if stock_mutation_product_item.quantity > stock.quantity
                                        raise_error = true
                                      else
                                        stock.quantity -= stock_mutation_product_item.quantity
                                        stock.save
                                      end
                                    end
                                    raise "Return quantity must be less than or equal to quantity on hand." if raise_error
                                  end
                                end
                              end
              
                              def approvable
                                if approved_date_was.present?
                                  errors.add(:base, "Sorry, stock mutation #{number} is already approved")
                                elsif destination_warehouse.warehouse_type.eql?("central")
                                  errors.add(:base, "Sorry, stock mutation #{number} is not approvable")
                                end
                              end
            
                              def prevent_delete_if_mutation_approved
                                if approved_date.present? || received_date.present?
                                  errors.add(:base, "Sorry, stock mutation #{number} cannot be deleted")                                  
                                  throw :abort
                                end
                              end
            
                              def editable
                                errors.add(:base, "The record cannot be edited") if approved_date.present? || received_date.present?
                              end
          
                              def apologize_to_previous_destination_store
                                notification = Notification.new(event: "New Notification", body: "Sorry, stock mutation #{number} has been cancelled", user_id: audits.where(action: "update").select(:user_id, :user_type).first.user.id)
                                destination_warehouse = Warehouse.where(id: destination_warehouse_id_was).select(:id).first
                                destination_warehouse.sales_promotion_girls.joins(:user).select("users.id AS user_id").each do |sales_promotion_girl|
                                  notification.recipients.build user_id: sales_promotion_girl.user_id, notified: false, read: false
                                end
                                notification.save
                              end
  
                              def notify_origin_store
                                notification = Notification.new(event: "New Notification", body: "Please send #{destination_warehouse.name} a stock mutation #{number}", user_id: audits.where(action: "create").select(:user_id, :user_type).first.user.id)
                                origin_warehouse.sales_promotion_girls.joins(:user).select("users.id AS user_id").each do |sales_promotion_girl|
                                  notification.recipients.build user_id: sales_promotion_girl.user_id, notified: false, read: false
                                end
                                notification.save
                              end

                              def notify_destination_store
                                notification = Notification.new(event: "New Notification", body: "Stock Mutation #{number} will arrive soon", user_id: audits.where(action: "create").select(:user_id, :user_type).first.user.id)
                                destination_warehouse.sales_promotion_girls.joins(:user).select("users.id AS user_id").each do |sales_promotion_girl|
                                  notification.recipients.build user_id: sales_promotion_girl.user_id, notified: false, read: false
                                end
                                notification.save
                              end

                              def notify_new_destination_store
                                notification = Notification.new(event: "New Notification", body: "Stock Mutation #{number} will arrive soon", user_id: audits.where(action: "update").select(:user_id, :user_type).first.user.id)
                                destination_warehouse.sales_promotion_girls.joins(:user).select("users.id AS user_id").each do |sales_promotion_girl|
                                  notification.recipients.build user_id: sales_promotion_girl.user_id, notified: false, read: false
                                end
                                notification.save
                              end

                              def notify_warehouse
                                notification = Notification.new(event: "New Notification", body: "Stock Mutation #{number} will arrive soon", user_id: audits.where(action: "create").select(:user_id, :user_type).first.user.id)
                                User.joins(:roles).where("roles.name = 'staff' OR roles.name = 'manager' OR roles.name = 'accountant'").select(:id).each do |user|
                                  notification.recipients.build user_id: user.id, notified: false, read: false
                                end
                                notification.save
                              end
              
                              def notify_new_warehouse
                                notification = Notification.new(event: "New Notification", body: "Stock Mutation #{number} will arrive soon", user_id: audits.where(action: "update").select(:user_id, :user_type).first.user.id)
                                User.joins(:roles).where("roles.name = 'staff' OR roles.name = 'manager' OR roles.name = 'accountant'").select(:id).each do |user|
                                  notification.recipients.build user_id: user.id, notified: false, read: false
                                end
                                notification.save
                              end
    
                              def delete_tracks
                                audits.destroy_all
                              end
    
                              def courier_available
                                errors.add(:courier_id, "does not exist!") if courier_id.present? && Courier.where(id: courier_id).select("1 AS one").blank?
                              end

                              def origin_warehouse_available
                                errors.add(:origin_warehouse_id, "does not exist!") if (origin_warehouse_id.present? && Warehouse.not_central.where(id: origin_warehouse_id).select("1 AS one").blank?) || (origin_warehouse_id.present? && destination_warehouse_id.present? && origin_warehouse_id == destination_warehouse_id)
                              end

                              def destination_warehouse_available
                                if (!mutation_type.eql?("store to warehouse") && destination_warehouse_id.present? && Warehouse.not_central.where(id: destination_warehouse_id).select("1 AS one").blank?) || (origin_warehouse_id.present? && destination_warehouse_id.present? && origin_warehouse_id == destination_warehouse_id)
                                  errors.add(:destination_warehouse_id, "does not exist!")
                                elsif (mutation_type.eql?("store to warehouse") && destination_warehouse_id.present? && Warehouse.central.where(id: destination_warehouse_id).select("1 AS one").blank?) || (origin_warehouse_id.present? && destination_warehouse_id.present? && origin_warehouse_id == destination_warehouse_id)
                                  errors.add(:destination_warehouse_id, "does not exist!")
                                end
                              end
    
                              def generate_number
                                number_id = if mutation_type.eql?("store to warehouse")
                                  "RW"
                                else
                                  "RGO"
                                end
          
                                warehouse_code = Warehouse.select(:code).where(id: origin_warehouse_id).first.code
                                today = Date.current
                                current_month = today.month.to_s.rjust(2, '0')
                                current_year = today.strftime("%y").rjust(2, '0')
                                existed_numbers = StockMutation.where("number LIKE '#{warehouse_code}#{number_id}#{current_month}#{current_year}%'").select(:number).order(:number)
                                if existed_numbers.blank?
                                  new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}0001"
                                else
                                  if existed_numbers.length == 1
                                    seq_number = existed_numbers[0].number.split("#{warehouse_code}#{number_id}#{current_month}#{current_year}").last
                                    if seq_number.to_i > 1
                                      new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}0001"
                                    else
                                      new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}#{seq_number.succ}"
                                    end
                                  else
                                    last_seq_number = ""
                                    existed_numbers.each_with_index do |existed_number, index|
                                      seq_number = existed_number.number.split("#{warehouse_code}#{number_id}#{current_month}#{current_year}").last
                                      if seq_number.to_i > 1 && index == 0
                                        new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}0001"
                                        break                              
                                      elsif last_seq_number.eql?("")
                                        last_seq_number = seq_number
                                      elsif (seq_number.to_i - last_seq_number.to_i) > 1
                                        new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}#{last_seq_number.succ}"
                                        break
                                      elsif index == existed_numbers.length - 1
                                        new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}#{seq_number.succ}"
                                      else
                                        last_seq_number = seq_number
                                      end
                                    end
                                  end                        
                                end

                                self.number = new_number
                              end
                            end
