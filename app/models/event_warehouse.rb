class EventWarehouse < ApplicationRecord
  attr_accessor :wrhs_code, :wrhs_name, :add_items_to_gift_list,
    :event_type, :remove
  
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
      validates :discount_amount, presence: {message: "can't be blank if gift list is empty"}, if: proc{|ew| ew.event_type.present? && ew.event_type.strip.eql?("gift") && ew.add_items_to_gift_list.strip.eql?("no")}
        validates :discount_amount, numericality: {greater_than: 0}, if: proc { |ew| ew.event_type.present? && ew.event_type.strip.eql?("gift") && ew.discount_amount.present? }
          
          after_create :save_all_gift_items, if: proc{|ew| ew.event_type.present? && ew.event_type.strip.eql?("gift") && ew.add_items_to_gift_list.eql?("yes")}
              
            private

            def save_all_gift_items
              warehouse.stock_products.each do |stock_product|
                event_product = event_products.new product_id: stock_product.product_id
                event_product.save
              end
            end

          end
