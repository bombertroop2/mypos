class Supervisor < ActiveRecord::Base
  has_many :sales_promotion_girls, through: :warehouses
  has_many :warehouses

  validates :code, :name, :address, presence: true
  validates :code, uniqueness: true
  validates :email, uniqueness: true, if: Proc.new { |spv| spv.email.present? }

    before_validation :titleize_name, :upcase_code

    def titleize_name
      self.name = name.titleize
    end

    def upcase_code
      self.code = code.upcase
    end
  end
