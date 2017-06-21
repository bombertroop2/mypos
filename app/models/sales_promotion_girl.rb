class SalesPromotionGirl < ApplicationRecord
  audited on: [:create, :update]
  #  resourcify
  
  belongs_to :warehouse
  has_one :user, dependent: :destroy

  
  #  after_update :unlink_from_user_if_role_downgraded

  validates :mobile_phone, :address, :name, :province, :warehouse_id, :gender, :role, presence: true
  validates :identifier, uniqueness: true
  validate :warehouse_has_supervisor?, :gender_available, :warehouse_available, :role_available
  
  #  accepts_nested_attributes_for :user, reject_if: proc {|attributes| attributes[:spg_role].eql?("spg") or attributes[:spg_role].blank?}
  
  before_save :titleize_name
  before_create :create_identifier
  before_destroy :delete_tracks
  after_save :update_user_columns, on: :update

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
  
  def update_user_columns
    if user.present?
      user.name = name
      user.mobile_phone = mobile_phone
      user.gender = gender
      user.role = role
      user.save validate: false
    end
  end
  
  def delete_tracks
    audits.destroy_all
  end

  def gender_available
    SalesPromotionGirl::GENDERS.select{ |x| x[1] == gender }.first.first
  rescue
    errors.add(:gender, "does not exist!") if gender.present?
  end
  
  def warehouse_available
    errors.add(:warehouse_id, "does not exist!") if warehouse_id.present? && Warehouse.where(id: warehouse_id).where("warehouse_type <> 'central'").select("1 AS one").blank?
  end
  
  def role_available
    ROLES.select{ |x| x[1] == role }.first.first
  rescue
    errors.add(:role, "does not exist!") if role.present?
  end
  
  def warehouse_has_supervisor?
    errors.add(:warehouse_id, "is being supervised by another supervisor") if Warehouse.has_supervisor?(warehouse_id) && (warehouse_id_changed? || (role_changed? && persisted?)) && role.eql?("supervisor")
  end
  
  #  def unlink_from_user_if_role_downgraded
  #    user.destroy if role_was.eql?("cashier") and role.eql?("spg")
  #  end

  def titleize_name
    self.name = name.titleize
  end

  def create_identifier
    spg_collections = warehouse.sales_promotion_girls
    self.identifier = spg_collections.count.eql?(0) ? "#{warehouse.code}00001" : spg_collections.order("id DESC").limit(1).pluck(:identifier).join.succ
  end
end
