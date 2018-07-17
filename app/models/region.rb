class Region < CommonField
  audited on: [:create, :update]
  has_many :warehouses, dependent: :restrict_with_error
  has_many :sales_promotion_girls, through: :warehouses
  has_many :supervisors, through: :warehouses
  has_one :warehouse_relation, -> {select("1 AS one")}, class_name: "Warehouse"

  before_validation :upcase_code

  validates :code, uniqueness: true
  validate :code_not_changed

  before_destroy :delete_tracks

  private

  def delete_tracks
    audits.destroy_all
  end

  def upcase_code
    self.code = code.upcase.gsub(" ","").gsub("\t","")
  end
  
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && warehouse_relation.present?
  end
end
