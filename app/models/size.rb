class Size < ApplicationRecord
  belongs_to :size_group
  has_many :product_details, dependent: :restrict_with_error
  has_one :product_detail_relation, -> {select("1 AS one")}, class_name: "ProductDetail"
  validates :size, presence: true#, uniqueness: {scope: :size_group_id}
  validate :size_not_changed
  
  private
  
  # apabila sudah ada relasi dengan table lain maka tidak dapat ubah code
  def size_not_changed
    errors.add(:size, "change is not allowed!") if size_changed? && persisted? && product_detail_relation.present?
  end
end
