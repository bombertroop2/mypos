class Vendor < ActiveRecord::Base

  validates :code, presence: true, uniqueness: true
  validates :name, :address, :value_added_tax, :terms_of_payment, presence: true
  #  validates :email, uniqueness: true, if: proc {|vendor| vendor.email.present?}
  #    validates :pic_email, uniqueness: true, if: proc {|vendor| vendor.pic_email.present?}
  validates :terms_of_payment, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc {|vendor| vendor.terms_of_payment.present?}
    validate :code_not_changed

      
    VAT = [
      ["Include", "include"],
      ["Exclude", "exclude"],
    ]

    has_many :products, dependent: :restrict_with_error
    #  has_many :purchase_orders

    before_validation :upcase_code

    private

    def upcase_code
      self.code = code.upcase
    end
    
    def code_not_changed
      errors.add(:code, "change is not allowed!") if code_changed? && persisted? && products.present?
    end
  end
