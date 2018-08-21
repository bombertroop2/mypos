class CoaType < ApplicationRecord
  validates :code, :name, presence: true
  has_many :coas
  has_one :coa_relation, -> {select("1 AS one")}, class_name: "Coa"
  before_validation :upcase_code
  before_destroy :delete_tracks

  private
  def delete_tracks
    audits.destroy_all
  end

  def upcase_code
    self.code = code.upcase.gsub(" ","").gsub("\t","")
  end

  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && coa_relation.present?
  end
end
