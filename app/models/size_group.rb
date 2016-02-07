class SizeGroup < ActiveRecord::Base
  has_many :sizes, dependent: :destroy
  has_many :products
  validates :code, presence: true, uniqueness: true

  accepts_nested_attributes_for :sizes,
#    reject_if: :all_blank,
    allow_destroy: true

  before_validation :upcase_code

  def upcase_code
    self.code = code.upcase
  end

end
