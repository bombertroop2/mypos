class ProductColor < ApplicationRecord
  belongs_to :product
  belongs_to :color
  
  attr_accessor :code, :name, :selected_color_id
end
