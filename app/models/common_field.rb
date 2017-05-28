class CommonField < ApplicationRecord
  before_validation :strip_string_values
  validates :code, :name, presence: true

	# We will need a way to know which animals
  # will subclass the Animal model
  def self.races
    %w(Brand Color GoodsType Model Region PriceCode)
  end
  
  private
  
  def strip_string_values
    self.code = code.strip
  end

end
