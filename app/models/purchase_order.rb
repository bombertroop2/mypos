class PurchaseOrder < ApplicationRecord
  audited on: [:create, :update], except: [:receiving_value, :payment_status]
  has_associated_audits

  belongs_to :vendor
  belongs_to :warehouse
  
  has_many :account_payable_purchases, as: :purchase, dependent: :restrict_with_error
  has_many :purchase_order_products, dependent: :destroy
  has_many :purchase_order_details, through: :purchase_order_products
  has_many :products, through: :purchase_order_products
  has_many :received_purchase_orders
  has_many :purchase_returns

  attr_accessor :receiving_po, :closing_po, :edit_document

  before_validation :set_type, :set_status, on: :create
      
  validates :vendor_id, :request_delivery_date, :warehouse_id, :purchase_order_date, presence: true, if: proc { |po| !po.receiving_po }
    validates :request_delivery_date, date: {after: proc { Date.current }, message: 'must be after today' }, if: :is_validable
      validates :purchase_order_date, date: {before_or_equal_to: proc { |po| po.request_delivery_date }, message: 'must be before or equal to request delivery date' }, if: proc{|po| po.is_po_date_validable && po.request_delivery_date.present?}
        validates :purchase_order_date, date: {after_or_equal_to: proc { Date.current }, message: 'must be after or equal to today' }, if: proc {|po| po.is_po_date_validable}
          validate :prevent_update_if_article_received, on: :update
          validate :disable_receive_po_if_finish, :disable_receive_po_if_po_closed, if: proc { |po| po.receiving_po }
#            validate :minimum_one_color_per_product, if: proc {|po| !po.receiving_po && !po.closing_po }                  
              validate :prevent_close_if_article_status_not_partial, if: proc { |po| po.closing_po }
                validates :first_discount, numericality: {greater_than: 0, less_than_or_equal_to: 100}, if: proc {|po| !po.receiving_po && po.first_discount.present?}
                  validates :second_discount, numericality: {greater_than: 0, less_than_or_equal_to: 100}, if: proc {|po| po.second_discount.present?}
                    validate :prevent_adding_second_discount_if_first_discount_is_100, if: proc {|po| po.second_discount.present?}
                      validate :prevent_adding_second_discount_if_total_discount_greater_than_100, if: proc {|po| !po.receiving_po && po.second_discount.present? && !po.is_additional_disc_from_net}
                        validates :first_discount, presence: true, if: proc {|po| po.second_discount.present?}
                          validate :vendor_available, :warehouse_available
                                  
                          before_save :set_nil_to_is_additional_disc_from_net, if: proc {|po| !po.receiving_po && !po.closing_po}
                          before_update :calculate_order_value, if: proc {|po| !po.receiving_po && !po.closing_po && !po.edit_document}
                            #                            before_update :is_product_has_one_color?, if: proc {|po| !po.receiving_po && !po.closing_po}
                            before_update :calculate_net_amount, if: proc{|po| po.edit_document}
                              before_create :calculate_net_amount, :generate_number
                              before_destroy :prevent_delete_if_article_received, :delete_tracks
                              after_update :update_product_cost, if: proc{|po| po.purchase_order_date_changed?}

                                accepts_nested_attributes_for :purchase_order_products, allow_destroy: true
                                accepts_nested_attributes_for :received_purchase_orders
                                          
                                def quantity_received
                                  quantity = 0
                                  purchase_order_products.select(:id).each do |pop|
                                    quantity += pop.purchase_order_details.sum(:receiving_qty)
                                  end
                                  quantity
                                end


                                protected
                                
                                def is_po_date_validable
                                  return false if receiving_po || closing_po
                                  return false if purchase_order_date.blank?
                                  return true
                                end

                                private
                              
                                def update_product_cost
                                  purchase_order_products.select(:id, :cost_list_id, :product_id, :purchase_order_id).each do |purchase_order_product|
                                    #                                    product = purchase_order_product.product
                                    #                                    purchase_order_product.cost_list_id = product.active_cost_by_po_date(purchase_order_date).id
                                    purchase_order_product.purchase_order_date = purchase_order_date
                                    purchase_order_product.save
                                  end
                                end
                              
                                def delete_tracks
                                  audits.destroy_all
                                end

                                def vendor_available
                                  @vendor = Vendor.where(id: vendor_id).select(:value_added_tax, :is_taxable_entrepreneur, :code).first
                                  errors.add(:vendor_id, "does not exist!") if vendor_id.present? && @vendor.blank?
                                end

                                def warehouse_available
                                  errors.add(:warehouse_id, "does not exist!") if warehouse_id.present? && Warehouse.where(id: warehouse_id, is_active: true).where("warehouse_type = 'central'").select("1 AS one").blank?
                                end
                                          
                                def get_vat_in_money(purchase_order)
                                  value_after_discount(purchase_order) * 0.1
                                end
                                          
                                def value_after_discount(purchase_order)
                                  value_after_first_discount = purchase_order.order_value - purchase_order.order_value * (purchase_order.first_discount.to_f / 100)
                                  value_after_second_discount = if purchase_order.is_additional_disc_from_net
                                    value_after_first_discount - value_after_first_discount * (purchase_order.second_discount.to_f / 100)
                                  elsif purchase_order.second_discount.present?
                                    purchase_order.order_value - purchase_order.order_value * ((purchase_order.first_discount.to_f + purchase_order.second_discount.to_f) / 100)
                                  end
                                  return value_after_second_discount || value_after_first_discount
                                end
                                          
                                def calculate_net_amount
                                  self.net_amount = if value_added_tax.eql?("exclude")
                                    value_after_discount(self) + get_vat_in_money(self)
                                  else
                                    value_after_discount(self)
                                  end
                                end
                                                                                    
                                def prevent_adding_second_discount_if_total_discount_greater_than_100
                                  errors.add(:second_discount, "can't be added, because total discount (1st discount + 2nd discount) is greater than 100%") if (first_discount + second_discount) > 100
                                end
                                      
                                def prevent_adding_second_discount_if_first_discount_is_100
                                  errors.add(:second_discount, "can't be added, because first discount is already 100%") if first_discount == 100
                                end
                                      
                                def set_nil_to_is_additional_disc_from_net                                        
                                  self.is_additional_disc_from_net = nil if second_discount.blank?
                                end
                                      
              
                                def disable_receive_po_if_finish                         
                                  errors.add(:base, "Sorry, this PO's status was finished, you can't receive products anymore") if status.eql?("Finish")
                                end
                
                                def disable_receive_po_if_po_closed
                                  errors.add(:base, "Sorry, this PO's status was closed, you can't receive products anymore") if status.eql?("Closed")
                                end

                
                                def prevent_close_if_article_status_not_partial
                                  if !status_was.eql?("Partial") && status_changed? && persisted? && status.eql?("Closed")
                                    errors.add(:base, "Sorry, that PO cannot be closed")
                                  elsif status_was.eql?("Closed") && persisted? && status.eql?("Closed")
                                    errors.add(:base, "Sorry, that PO already closed")
                                  end
                                end
              
                                def prevent_delete_if_article_received
                                  if !status_was.eql?("Open")
                                    errors.add(:base, "Sorry, PO #{number} cannot be deleted")                                  
                                    throw :abort
                                  end
                                end

                                def prevent_update_if_article_received
                                  errors.add(:base, "Sorry, PO #{number} cannot be changed") if !receiving_po && !closing_po && !status.eql?("Open")
                                end


                                def is_validable
                                  return false if receiving_po || closing_po
                                  return true if request_delivery_date.present?
                                  #                                  unless request_delivery_date.eql?(request_delivery_date_was)
                                  #                                    return true if request_delivery_date_was.blank?
                                  #                                    return false if Time.current.to_date >= request_delivery_date_was
                                  #                                    return true if Time.current.to_date < request_delivery_date_was
                                  #                                  end
                                  return false
                                end
                  

                                def calculate_order_value
                                  total_product_value = 0                                            
                                  purchase_order_products.each do |pop|
                                    unless pop._destroy                                                  
                                      total_quantity = pop.purchase_order_details.map(&:quantity).compact.sum
                                      cost_list = pop.cost_list
                                      if cost_list.present? && purchase_order_date.eql?(purchase_order_date_was)
                                        total_product_value += cost_list.cost * total_quantity
                                      else
                                        total_product_value += pop.product.active_cost_by_po_date(purchase_order_date).cost * total_quantity 
                                      end
                                    end                              
                                  end
        
                                  #                                            unless order_value == total_product_value
                                  self.order_value = total_product_value
                                  #                                            end
                                end

                                def generate_number
                                  self.value_added_tax = @vendor.value_added_tax rescue nil
                                  self.is_taxable_entrepreneur = @vendor.is_taxable_entrepreneur rescue nil
                                  pkp_code = is_taxable_entrepreneur ? "1" : "0"
                                  today = Date.current
                                  current_month = today.month.to_s.rjust(2, '0')
                                  current_year = today.strftime("%y").rjust(2, '0')
                                  existed_numbers = PurchaseOrder.where("number LIKE '#{pkp_code}POR#{@vendor.code}#{current_month}#{current_year}%'").select(:number).order(:number)
                                  if existed_numbers.blank?
                                    new_number = "#{pkp_code}POR#{@vendor.code}#{current_month}#{current_year}0001"
                                  else
                                    if existed_numbers.length == 1
                                      seq_number = existed_numbers[0].number.split("#{pkp_code}POR#{@vendor.code}#{current_month}#{current_year}").last
                                      if seq_number.to_i > 1
                                        new_number = "#{pkp_code}POR#{@vendor.code}#{current_month}#{current_year}0001"
                                      else
                                        new_number = "#{pkp_code}POR#{@vendor.code}#{current_month}#{current_year}#{seq_number.succ}"
                                      end
                                    else
                                      last_seq_number = ""
                                      existed_numbers.each_with_index do |existed_number, index|
                                        seq_number = existed_number.number.split("#{pkp_code}POR#{@vendor.code}#{current_month}#{current_year}").last
                                        if seq_number.to_i > 1 && index == 0
                                          new_number = "#{pkp_code}POR#{@vendor.code}#{current_month}#{current_year}0001"
                                          break                              
                                        elsif last_seq_number.eql?("")
                                          last_seq_number = seq_number
                                        elsif (seq_number.to_i - last_seq_number.to_i) > 1
                                          new_number = "#{pkp_code}POR#{@vendor.code}#{current_month}#{current_year}#{last_seq_number.succ}"
                                          break
                                        elsif index == existed_numbers.length - 1
                                          new_number = "#{pkp_code}POR#{@vendor.code}#{current_month}#{current_year}#{seq_number.succ}"
                                        else
                                          last_seq_number = seq_number
                                        end
                                      end
                                    end                        
                                  end
                                  self.number = new_number
                                end

                                def set_type
                                  self.po_type = "POC"
                                end

                                def set_status
                                  self.status = "Open"
                                end
              
                                # method ini perlu di-refactor --start
#                                def minimum_one_color_per_product
#                                  is_valid = false
#                                  colors = Color.order(:id).select(:id)
#                                  purchase_order_products.each do |pop|
#                                    colors.each_with_index do |color, index|
#                                      if pop._destroy || pop.purchase_order_details.select{|pod| pod.color_id.eql?(color.id)}.size.eql?(pop.product.sizes.size)
#                                        is_valid = true
#                                        break
#                                      else
#                                        if index.eql?(colors.size - 1)
#                                          is_valid = false
#                                          break
#                                        end
#                                      end
#                                    end
#                  
#                                    break unless is_valid
#                                  end
#                
#                                  errors.add(:base, "Please insert at least one row of colors per product!") unless is_valid
#                                end
              
                                #                              def is_product_has_one_color?                
                                #                                is_valid = false
                                #                                colors = Color.order(:id).select(:id)
                                #                                purchase_order_products.each do |pop|
                                #                                  colors.each_with_index do |color, index|
                                #                                    if pop._destroy || pop.purchase_order_details.select{|pod| pod.color_id.eql?(color.id)}.map(&:quantity).compact.size.eql?(pop.product.sizes.size)
                                #                                      is_valid = true
                                #                                      break
                                #                                    else
                                #                                      if index.eql?(colors.size - 1)
                                #                                        is_valid = false
                                #                                        break
                                #                                      end
                                #                                    end
                                #                                  end
                                #                  
                                #                                  break unless is_valid
                                #                                end
                                #                
                                #                                unless is_valid
                                #                                  errors.add(:base, "Purchase order must have at least one item color per product!")
                                #                                  throw :abort
                                #                                end
                                #                              end
                                # method ini perlu di-refactor --end

                              end
