class CommonField < ActiveRecord::Base
  validates :code, :name, presence: true

	# We will need a way to know which animals
  # will subclass the Animal model
  def self.races
    %w(Brand Color GoodsType Model Region)
  end
end
