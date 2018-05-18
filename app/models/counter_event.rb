class CounterEvent < ApplicationRecord
  attr_accessor :counter_event_activation
  
  audited on: [:create, :update]

  has_many :counter_event_warehouses, dependent: :destroy
  has_many :counter_event_general_products, dependent: :destroy
  has_many :sale_products
  
  before_validation :remove_white_space, :upcase_code
  validates :code, :name, :start_date_time, :end_date_time, :counter_event_type, presence: true
  validates :counter_event_type, inclusion: { in: ["Discount(%)", "Special Price"],
    message: "%{value} is not a valid type" }
  validates :first_plus_discount, presence: true, if: proc{|counter_event| counter_event.counter_event_type.strip.eql?("Discount(%)")}
  validates :cash_discount, presence: true, if: proc{|counter_event| counter_event.counter_event_type.strip.eql?("Discount(Rp)")}
  validates :start_date_time, date: {after_or_equal_to: proc {Time.current}, message: 'must be after or equal to current time' }, if: proc{|evnt| evnt.start_date_time.present? && evnt.start_date_time_changed?}
  validates :end_date_time, date: {after: proc {|evnt| evnt.start_date_time}, message: 'must be after start time' }, if: proc{|evnt| evnt.start_date_time.present? && evnt.end_date_time.present?}
  validates :first_plus_discount, numericality: {greater_than: 0, less_than: 100}, if: proc {|evnt| evnt.first_plus_discount.present? && evnt.counter_event_type.strip.eql?("Discount(%)")}
  validates :second_plus_discount, numericality: {greater_than: 0, less_than: 100}, if: proc {|evnt| evnt.second_plus_discount.present? && evnt.counter_event_type.strip.eql?("Discount(%)")}
  validates :cash_discount, numericality: {greater_than: 0}, if: proc { |counter_event| counter_event.counter_event_type.strip.eql?("Discount(Rp)") && counter_event.cash_discount.present? }
  validates :special_price, presence: true, if: proc{|counter_event| counter_event.counter_event_type.strip.eql?("Special Price")}
  validates :special_price, numericality: {greater_than: 0}, if: proc { |counter_event| counter_event.counter_event_type.strip.eql?("Special Price") && counter_event.special_price.present? }
  validates :minimum_purchase_amount, presence: true, if: proc{|counter_event| counter_event.counter_event_type.strip.eql?("Gift")}
  validates :minimum_purchase_amount, numericality: {greater_than: 0}, if: proc { |counter_event| counter_event.counter_event_type.strip.eql?("Gift") && counter_event.minimum_purchase_amount.present? }
  validates :discount_amount, numericality: {greater_than: 0}, if: proc { |counter_event| counter_event.counter_event_type.strip.eql?("Gift") && counter_event.discount_amount.present? }
  validates :discount_amount, numericality: {less_than: proc {|counter_event| counter_event.minimum_purchase_amount}}, if: proc { |counter_event| counter_event.counter_event_type.strip.eql?("Gift") && counter_event.discount_amount.present? && counter_event.minimum_purchase_amount.present? }
  validate :editable, on: :update, unless: proc {|counter_event| counter_event.counter_event_activation.eql?("true")}
  validate :activable, on: :update, if: proc {|counter_event| counter_event.counter_event_activation.eql?("true")}
  #                              validate :activable, on: :create
  accepts_nested_attributes_for :counter_event_warehouses, allow_destroy: true
  accepts_nested_attributes_for :counter_event_general_products, allow_destroy: true

  before_destroy :deletable, :delete_tracks

  private

  def activable
    unless new_record?
      if is_active_changed? && persisted?
        cashier_opened = false
        counter_event_warehouses.select(:warehouse_id).each do |counter_event_warehouse|
          cashier_opened = CashierOpening.select("1 AS one").joins(:warehouse).where(["warehouse_id = ? AND DATE(open_date) = ? AND closed_at IS NULL AND DATE(open_date) >= ? AND DATE(open_date) <= ? AND warehouses.is_active = ?", counter_event_warehouse.warehouse_id, Date.current, start_date_time.to_date, end_date_time.to_date, true]).present?
          break
        end
        errors.add(:base, "Please close some cashiers and try again") if cashier_opened
      end
    else
      if start_date_time.present? && end_date_time.present?
        cashier_opened = false
        counter_event_warehouses.each do |counter_event_warehouse|
          cashier_opened = CashierOpening.select("1 AS one").joins(:warehouse).where(["warehouse_id = ? AND DATE(open_date) = ? AND closed_at IS NULL AND DATE(open_date) >= ? AND DATE(open_date) <= ? AND warehouses.is_active = ?", counter_event_warehouse.warehouse_id, Date.current, start_date_time.to_date, end_date_time.to_date, true]).present?
          break
        end
        errors.add(:base, "Please close some cashiers and try again") if cashier_opened
      end
    end
  end

  def deletable
    if start_date_time <= Time.current
      errors.add(:base, "The record cannot be deleted")
      throw :abort
    end
  end

  def editable
    errors.add(:base, "The record cannot be edited") if start_date_time <= Time.current
  end

  def delete_tracks
    audits.destroy_all
  end

  def remove_white_space
    self.code = code.strip
    self.name = name.strip
  end

  def upcase_code
    self.code = code.upcase.gsub(" ","")
  end
end
