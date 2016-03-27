class Size < ActiveRecord::Base
  belongs_to :size_group
  has_many :product_details, dependent: :restrict_with_error
  validates :size, presence: true, uniqueness: {scope: :size_group_id}
  validate :size_not_changed
  
  private
  
  # apabila sudah ada relasi dengan table lain maka tidak dapat ubah code
  def size_not_changed
    errors.add(:size, "change is not allowed!") if size_changed? && persisted? && product_details.present?
  end
end
