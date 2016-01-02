class Vendor < ActiveRecord::Base

  validates :code, presence: true, uniqueness: true
  validates :name, :address, presence: true
  validates :email, uniqueness: true, if: Proc.new {|vendor| vendor.email.present?}
  validates :pic_email, uniqueness: true, if: Proc.new {|vendor| vendor.pic_email.present?}

    has_many :products, dependent: :restrict_with_error
    #  has_many :purchase_orders

    before_validation :titleize_name, :upcase_code

    def titleize_name
      self.name = name.titleize
    end

    def upcase_code
      self.code = code.upcase
    end
  end
