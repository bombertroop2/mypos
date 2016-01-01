class Size < ActiveRecord::Base
  belongs_to :size_group
  has_many :product_details
  validates :size, presence: true, uniqueness: {scope: :size_group_id}
end
