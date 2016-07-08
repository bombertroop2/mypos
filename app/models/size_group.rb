class SizeGroup < ApplicationRecord
  has_many :products, dependent: :restrict_with_error
  has_many :sizes, dependent: :destroy
  has_one :product_relation, -> {select("1 AS one")}, class_name: "Product"
  validates :code, presence: true#, uniqueness: true
  validate :code_not_changed

  accepts_nested_attributes_for :sizes, allow_destroy: true

  before_validation :upcase_code
  
  private

  def upcase_code
    self.code = code.upcase
  end
  
  # apabila sudah ada relasi dengan table lain maka tidak dapat ubah code
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && product_relation.present?
  end

end
