class Event < ApplicationRecord
  attr_accessor :event_activation
  
  audited on: [:create, :update]

  has_many :event_warehouses, dependent: :destroy
  has_many :event_general_products, dependent: :destroy
  has_many :sale_products, dependent: :restrict_with_error
  has_many :sales, foreign_key: :gift_event_id, dependent: :restrict_with_error
  
  before_validation :remove_white_space, :upcase_code
  validates :code, :name, :start_date_time, :end_date_time, :event_type, presence: true
  validates :event_type, inclusion: { in: ["Discount(%)", "Discount(Rp)", "Special Price", "Buy 1 Get 1 Free", "Gift"],
    message: "%{value} is not a valid type" }
  validates :first_plus_discount, presence: true, if: proc{|event| event.event_type.strip.eql?("Discount(%)")}
    validates :cash_discount, presence: true, if: proc{|event| event.event_type.strip.eql?("Discount(Rp)")}
      validates :start_date_time, date: {after_or_equal_to: proc {Time.current}, message: 'must be after or equal to current time' }, if: proc{|evnt| evnt.start_date_time.present? && evnt.start_date_time_changed?}
        validates :end_date_time, date: {after: proc {|evnt| evnt.start_date_time}, message: 'must be after start time' }, if: proc{|evnt| evnt.start_date_time.present? && evnt.end_date_time.present?}
          validates :first_plus_discount, numericality: {greater_than: 0, less_than: 100}, if: proc {|evnt| evnt.first_plus_discount.present? && evnt.event_type.strip.eql?("Discount(%)")}
            validates :second_plus_discount, numericality: {greater_than: 0, less_than: 100}, if: proc {|evnt| evnt.second_plus_discount.present? && evnt.event_type.strip.eql?("Discount(%)")}
              validates :cash_discount, numericality: {greater_than: 0}, if: proc { |event| event.event_type.strip.eql?("Discount(Rp)") && event.cash_discount.present? }
                validates :special_price, presence: true, if: proc{|event| event.event_type.strip.eql?("Special Price")}
                  validates :special_price, numericality: {greater_than: 0}, if: proc { |event| event.event_type.strip.eql?("Special Price") && event.special_price.present? }
                    validates :minimum_purchase_amount, presence: true, if: proc{|event| event.event_type.strip.eql?("Gift")}
                      validates :minimum_purchase_amount, numericality: {greater_than: 0}, if: proc { |event| event.event_type.strip.eql?("Gift") && event.minimum_purchase_amount.present? }
                        validates :discount_amount, numericality: {greater_than: 0}, if: proc { |event| event.event_type.strip.eql?("Gift") && event.discount_amount.present? }
                          validates :discount_amount, numericality: {less_than: proc {|event| event.minimum_purchase_amount}}, if: proc { |event| event.event_type.strip.eql?("Gift") && event.discount_amount.present? && event.minimum_purchase_amount.present? }
                            validate :editable, on: :update, unless: proc {|event| event.event_activation.eql?("true")}
                              validate :activable, on: :update, if: proc {|event| event.event_activation.eql?("true")}
                                validate :activable, on: :create
                                accepts_nested_attributes_for :event_warehouses, allow_destroy: true
                                accepts_nested_attributes_for :event_general_products, allow_destroy: true
                    
                                before_destroy :delete_tracks
                            
                                private
                            
                                def activable
                                  unless new_record?
                                    if is_active_changed? && persisted?
                                      cashier_opened = false
                                      event_warehouses.select(:warehouse_id).each do |event_warehouse|
                                        cashier_opened = CashierOpening.select("1 AS one").joins(:warehouse).where(["warehouse_id = ? AND closed_at IS NULL AND DATE(open_date) >= ? AND DATE(open_date) <= ? AND warehouses.is_active = ?", event_warehouse.warehouse_id, start_date_time.to_date, end_date_time.to_date, true]).present?
                                        break
                                      end
                                      errors.add(:base, "Please close some cashiers and try again") if cashier_opened
                                    end
                                  else
                                    if start_date_time.present? && end_date_time.present?
                                      cashier_opened = false
                                      event_warehouses.each do |event_warehouse|
                                        cashier_opened = CashierOpening.select("1 AS one").joins(:warehouse).where(["warehouse_id = ? AND closed_at IS NULL AND DATE(open_date) >= ? AND DATE(open_date) <= ? AND warehouses.is_active = ?", event_warehouse.warehouse_id, start_date_time.to_date, end_date_time.to_date, true]).present?
                                        break
                                      end
                                      errors.add(:base, "Please close some cashiers and try again") if cashier_opened
                                    end
                                  end
                                end                                                            
                          
                                def editable
                                  if sales.select("1 AS one").present? || sale_products.select("1 AS one").present?
                                    errors.add(:base, "The record cannot be edited")
                                  else
                                    cashier_opened = false
                                    event_warehouses.each do |event_warehouse|
                                      cashier_opened = CashierOpening.select("1 AS one").joins(:warehouse).where(["warehouse_id = ? AND closed_at IS NULL AND DATE(open_date) >= ? AND DATE(open_date) <= ? AND warehouses.is_active = ?", event_warehouse.warehouse_id, start_date_time.to_date, end_date_time.to_date, true]).present?
                                      break
                                    end
                                    errors.add(:base, "Please close some cashiers and try again") if cashier_opened
                                  end
                                end
                    
                                def delete_tracks
                                  audits.destroy_all
                                end
  
                                def remove_white_space
                                  self.code = code.strip
                                  self.name = name.strip
                                end

                                def upcase_code
                                  self.code = code.upcase.gsub(" ","").gsub("\t","")
                                end
                              end
