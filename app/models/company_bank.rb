class CompanyBank < ApplicationRecord
  belongs_to :company
  has_many :company_bank_account_numbers, dependent: :destroy

  accepts_nested_attributes_for :company_bank_account_numbers, allow_destroy: true

  before_validation :strip_field_values

  validates :code, :name, presence: true
  validates :code, uniqueness: { scope: :company_id }, if: proc{|cb| cb.code.present? && cb.code_changed?}

    before_save :upcase_code

    private
  
    def upcase_code
      self.code = code.upcase
    end
  
    def strip_field_values
      self.code = code.strip.gsub(" ","").gsub("\t","")
      self.name = name.strip
    end

  end
