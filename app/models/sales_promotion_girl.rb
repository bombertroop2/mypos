class SalesPromotionGirl < ActiveRecord::Base
  belongs_to :warehouse

  before_save :titleize_name
  before_create :create_identifier

  validates :address, :name, :province, :warehouse_id, :gender, presence: true
  validates :identifier, uniqueness: true
  
  GENDERS = [
    ["Male", "male"],
    ["Female", "female"],
  ]

  private

  def titleize_name
    self.name = name.titleize
  end

  def create_identifier
    spg_collections = warehouse.sales_promotion_girls
    self.identifier = spg_collections.count.eql?(0) ? "#{warehouse.code}00001" : spg_collections.order("id DESC").limit(1).pluck(:identifier).join.succ
  end
end
