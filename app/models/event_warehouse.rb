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

  #        before_update :delete_old_products, if: proc {|ew| ew.select_different_products_changed? && ew.persisted? && ew.select_different_products == false}

  #          private
        
  #          def delete_old_products
  #            event_products.select(:id).destroy_all
  #          end
end
