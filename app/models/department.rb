class Department < ApplicationRecord
  audited on: [:create, :update]
  validates :code, :name, presence: true
  validate :code_not_changed
  has_many :coa_departments, dependent: :restrict_with_error
  has_one :coa_department_relation, -> {select("1 AS one")}, class_name: "CoaDepartment"
  before_validation :upcase_code
  before_destroy :delete_tracks

  def department_view
    "#{code} - #{name}"
  end

  private
  def delete_tracks
    audits.destroy_all
  end

  def upcase_code
    self.code = code.upcase.gsub(" ","").gsub("\t","")
  end

  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && coa_department_relation.present?
  end

end
