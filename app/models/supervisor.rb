class Supervisor < ActiveRecord::Base
  has_many :sales_promotion_girls, through: :warehouses
  has_many :warehouses, dependent: :restrict_with_error

  validates :code, :name, :address, presence: true
  validates :code, uniqueness: true
  validates :email, uniqueness: true, if: proc { |spv| spv.email.present? }
    validate :code_not_changed

    before_save :convert_email_value_to_nil

    before_validation :titleize_name, :upcase_code
    
    private
    
    def code_not_changed
      errors.add(:code, "change is not allowed!") if code_changed? && persisted? && warehouses.present?
    end
    
    def convert_email_value_to_nil
      self.email = nil unless email.present?
    end

    def titleize_name
      self.name = name.titleize
    end

    def upcase_code
      self.code = code.upcase
    end
  end
