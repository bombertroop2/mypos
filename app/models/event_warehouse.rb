class EventWarehouse < ApplicationRecord
  attr_accessor :wrhs_code, :wrhs_name, :event_type, :remove

  audited associated_with: :event, on: [:create, :update]
  
  belongs_to :event
  belongs_to :warehouse
  
  has_many :event_products, dependent: :destroy

  accepts_nested_attributes_for :event_products, allow_destroy: true
  
  YES_OR_NO = [
    ["Yes", "yes"],
    ["No", "no"]
  ]

  validates :warehouse_id, presence: true
  
  before_destroy :delete_tracks


  #        before_update :delete_old_products, if: proc {|ew| ew.select_different_products_changed? && ew.persisted? && ew.select_different_products == false}

  private
        
  #            def delete_old_products
  #              event_products.select(:id).destroy_all
  #            end

  def delete_tracks
    audits.destroy_all
  end
end
