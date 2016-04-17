class PurchaseOrder < ActiveRecord::Base
  belongs_to :vendor
  belongs_to :warehouse
  
  has_many :purchase_order_products, dependent: :destroy
  has_many :purchase_order_details, through: :purchase_order_products
  has_many :products, through: :purchase_order_products
  has_many :received_purchase_orders
  has_one :purchase_return

  attr_accessor :receiving_po, :deleting_po, :closing_po

  before_validation :generate_number, :set_type, :set_status, on: :create
  
  before_save :set_nil_to_is_additional_disc_from_net, :calculate_order_value, if: proc {|po| !po.receiving_po && !po.deleting_po && !po.closing_po}
    before_create :set_vat_and_entrepreneur_status
    before_update :is_product_has_one_color?, if: proc {|po| !po.receiving_po && !po.deleting_po && !po.closing_po}
    
      validates :number, :vendor_id, :request_delivery_date, :warehouse_id, :purchase_order_date, presence: true, unless: proc { |po| po.receiving_po }
        validates :number, uniqueness: true, unless: proc { |po| po.receiving_po }
          validates :request_delivery_date, date: {after: proc { Date.today }, message: 'must be after today' }, if: :is_validable
            validates :purchase_order_date, date: {before_or_equal_to: proc { |po| po.request_delivery_date }, message: 'must be before or equal to request delivery date' }, if: :is_po_date_validable
              validates :purchase_order_date, date: {after_or_equal_to: proc { Date.today }, message: 'must be after or equal to today' }, on: :create, if: proc {|po| po.purchase_order_date.present?}
                validates :purchase_order_date, date: {after_or_equal_to: proc { |po| po.created_at }, message: 'must be after or equal to created date' }, on: :update, if: proc {|po| po.purchase_order_date.present? && !po.receiving_po && !po.closing_po && !po.deleting_po}
                  validate :prevent_update_if_article_received, on: :update
                  validate :disable_receive_po_if_finish, :disable_receive_po_if_po_deleted, :disable_receive_po_if_po_closed, if: proc { |po| po.receiving_po }
                    validate :minimum_one_color_per_product, if: proc {|po| !po.receiving_po && !po.deleting_po && !po.closing_po}
                      validate :prevent_delete_if_article_received, if: proc { |po| po.deleting_po }
                        validate :prevent_close_if_article_status_not_partial, if: proc { |po| po.closing_po }
                          validates :first_discount, numericality: {greater_than: 0, less_than_or_equal_to: 100}, if: proc {|po| po.first_discount.present?}
                            validates :second_discount, numericality: {greater_than: 0, less_than_or_equal_to: 100}, if: proc {|po| po.second_discount.present?}
                              validate :prevent_adding_second_discount_if_first_discount_is_100, if: proc {|po| po.second_discount.present?}
                                validate :prevent_adding_second_discount_if_total_discount_greater_than_100, if: proc {|po| po.second_discount.present? && !po.is_additional_disc_from_net}
                                  validates :first_discount, presence: true, if: proc {|po| po.second_discount.present?}
                                    validate :prevent_combining_discount, if: proc {|po| po.first_discount.present? && po.price_discount.present?}
                                      validates :price_discount, numericality: true, if: proc { |po| po.price_discount.present? }
                                        validates :price_discount, numericality: {greater_than: 0}, if: proc { |po| po.price_discount.is_a?(Numeric) }
                                
                                          accepts_nested_attributes_for :purchase_order_products, allow_destroy: true
                                          accepts_nested_attributes_for :received_purchase_orders

                                          private
                                          
                                          def prevent_adding_second_discount_if_total_discount_greater_than_100
                                            errors.add(:second_discount, "can't be added, because total discount (1st discount + 2nd discount) is greater than 100%") if (first_discount + second_discount) > 100
                                          end
                                      
                                          def prevent_adding_second_discount_if_first_discount_is_100
                                            errors.add(:second_discount, "can't be added, because first discount is already 100%") if first_discount == 100
                                          end
                                      
                                          def set_nil_to_is_additional_disc_from_net                                        
                                            self.is_additional_disc_from_net = nil if second_discount.blank?
                                          end
                                      
                                          def set_vat_and_entrepreneur_status
                                            self.value_added_tax = vendor.value_added_tax
                                            self.is_taxable_entrepreneur = vendor.is_taxable_entrepreneur
                                            return true
                                          end
              
                                          def prevent_combining_discount
                                            errors.add(:first_discount, "can't be combined with price discount")
                                            errors.add(:price_discount, "can't be combined with double discount")
                                          end

                                          def disable_receive_po_if_finish                         
                                            errors.add(:base, "Sorry, this PO's status was finished, you can't receive products anymore") if status.eql?("Finish")
                                          end
                
                                          def disable_receive_po_if_po_deleted
                                            errors.add(:base, "Sorry, this PO's status was deleted, you can't receive products") if status.eql?("Deleted")
                                          end
                
                                          def disable_receive_po_if_po_closed
                                            errors.add(:base, "Sorry, this PO's status was closed, you can't receive products anymore") if status.eql?("Closed")
                                          end

                
                                          def prevent_close_if_article_status_not_partial
                                            if !status_was.eql?("Partial") && status_changed? && persisted? && status.eql?("Closed")
                                              errors.add(:base, "Sorry, this PO is not closeable")
                                            elsif status_was.eql?("Closed") && persisted? && status.eql?("Closed")
                                              errors.add(:base, "Sorry, this PO already closed")
                                            end
                                          end
              
                                          def prevent_delete_if_article_received
                                            if !status_was.eql?("Open") && status_changed? && persisted? && status.eql?("Deleted")
                                              errors.add(:base, "Sorry, this PO is not deleteable")
                                            elsif status_was.eql?("Deleted") && persisted? && status.eql?("Deleted")
                                              errors.add(:base, "Sorry, this PO already deleted")
                                            end
                                          end

                                          def prevent_update_if_article_received
                                            errors.add(:base, "Sorry, this PO is not updateable") if !receiving_po && !deleting_po && !closing_po && !status.eql?("Open")
                                          end


                                          def is_validable
                                            return false if receiving_po || closing_po || deleting_po
                                            return true if request_delivery_date.present?
                                            unless request_delivery_date.eql?(request_delivery_date_was)
                                              return true if request_delivery_date_was.blank?
                                              return false if Date.today >= request_delivery_date_was
                                              return true if Date.today < request_delivery_date_was
                                            end
                                            return false
                                          end
                  
                                          def is_po_date_validable
                                            return false if receiving_po || closing_po || deleting_po
                                            return false if request_delivery_date.blank? || purchase_order_date.blank?
                                            return true
                                          end

                                          def calculate_order_value
                                            total_product_value = 0
                                            purchase_order_products.each do |pop|
                                              total_quantity = pop.purchase_order_details.map(&:quantity).compact.sum
                                              total_product_value += pop.product.cost * total_quantity 
                                            end
        
                                            unless order_value == total_product_value
                                              if (price_discount.present? && price_discount <= total_product_value) || price_discount.blank?
                                                self.order_value = total_product_value
                                              else
                                                errors.add(:price_discount, "must be less than or equal to order value")
                                                return false
                                              end
                                            end
                                          end

                                          def generate_number
                                            pkp_code = is_taxable_entrepreneur ? "1" : "0"
                                            last_po_number = PurchaseOrder.where("number LIKE '#{pkp_code}%'").select(:number).limit(1).order("id DESC").first.number rescue nil
                                            today = Date.today
                                            current_month = today.month.to_s.rjust(2, '0')
                                            current_year = today.strftime("%y").rjust(2, '0')
                                            if last_po_number
                                              seq_number = last_po_number.split(last_po_number.scan(/POR\d.{3}/).first).last.succ
                                              new_po_number = "#{pkp_code}#{(warehouse.code if warehouse)}POR#{current_month}#{current_year}#{seq_number}"
                                            else
                                              new_po_number = "#{pkp_code}#{(warehouse.code if warehouse)}POR#{current_month}#{current_year}0001"
                                            end
                                            self.number = new_po_number
                                          end

                                          def set_type
                                            self.po_type = "POC"
                                          end

                                          def set_status
                                            self.status = "Open"
                                          end
              
                                          def minimum_one_color_per_product
                                            is_valid = false
                                            colors = Color.order :id
                                            purchase_order_products.each do |pop|
                                              colors.each_with_index do |color, index|
                                                if pop.purchase_order_details.select{|pod| pod.color_id.eql?(color.id)}.size.eql?(pop.product.sizes.size)
                                                  is_valid = true
                                                  break
                                                else
                                                  if index.eql?(colors.size - 1)
                                                    is_valid = false
                                                    break
                                                  end
                                                end
                                              end
                  
                                              break unless is_valid
                                            end
                
                                            errors.add(:base, "Please insert at least one column per product!") unless is_valid
                                          end
              
                                          def is_product_has_one_color?                
                                            is_valid = false
                                            colors = Color.order :id
                                            purchase_order_products.each do |pop|
                                              colors.each_with_index do |color, index|
                                                if pop.purchase_order_details.select{|pod| pod.color_id.eql?(color.id)}.map(&:quantity).compact.size.eql?(pop.product.sizes.size)
                                                  is_valid = true
                                                  break
                                                else
                                                  if index.eql?(colors.size - 1)
                                                    is_valid = false
                                                    break
                                                  end
                                                end
                                              end
                  
                                              break unless is_valid
                                            end
                
                                            unless is_valid
                                              errors.add(:base, "Purchase order must have at least one item color per product!")
                                              false
                                            end
                                          end

                                        end
