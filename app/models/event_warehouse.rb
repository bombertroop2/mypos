class EventWarehouse < ApplicationRecord
  attr_accessor :wrhs_code, :wrhs_name, :event_type, :remove
  
  belongs_to :event
  belongs_to :warehouse
  
  has_many :event_products, dependent: :destroy

  accepts_nested_attributes_for :event_products, allow_destroy: true
  
  YES_OR_NO = [
    ["Yes", "yes"],
    ["No", "no"]
  ]

  validates :warehouse_id, presence: true
  validates :minimum_purchase_amount, presence: true, if: proc{|ew| ew.event_type.present? && ew.event_type.strip.eql?("gift")}
    validates :minimum_purchase_amount, numericality: {greater_than: 0}, if: proc { |ew| ew.event_type.present? && ew.event_type.strip.eql?("gift") && ew.minimum_purchase_amount.present? }
      validates :discount_amount, numericality: {greater_than: 0}, if: proc { |ew| ew.event_type.present? && ew.event_type.strip.eql?("gift") && ew.discount_amount.present? }

      end
