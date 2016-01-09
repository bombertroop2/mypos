class SalesPromotionGirl < ActiveRecord::Base
  belongs_to :warehouse
  has_one :user, dependent: :destroy

  before_save :titleize_name
  before_create :create_identifier

  validates :address, :name, :province, :warehouse_id, :gender, :role, presence: true
  validates :identifier, uniqueness: true
  
  accepts_nested_attributes_for :user, reject_if: proc {|attributes| attributes[:spg_role].eql?("spg") or attributes[:spg_role].blank?}
  
  GENDERS = [
    ["Male", "male"],
    ["Female", "female"],
  ]
  
  ROLES = [
    ["SPG", "spg"],
    ["Cashier", "cashier"],
    ["Supervisor", "supervisor"],
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
