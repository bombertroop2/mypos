class CounterEventGeneralProduct < ApplicationRecord
  audited associated_with: :counter_event, on: :create

  belongs_to :counter_event
  belongs_to :product

  attr_accessor :prdct_code, :prdct_name

  before_destroy :delete_tracks

  private

  def delete_tracks
    audits.destroy_all
  end
end
