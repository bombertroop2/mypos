class EventProduct < ApplicationRecord
  attr_accessor :prdct_code, :prdct_name
  audited associated_with: :event_warehouse, on: :create
  
  belongs_to :event_warehouse
  belongs_to :product
  
  validates :product_id, presence: true
  
  before_destroy :delete_tracks
  
  private
  
  def delete_tracks
    audits.destroy_all
  end

end
