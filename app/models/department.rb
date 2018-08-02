class Department < ApplicationRecord
  audited on: [:create, :update]
  validates :code, :name, presence: true
  has_many :coa_departments
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

end
