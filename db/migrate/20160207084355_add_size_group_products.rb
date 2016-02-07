class AddSizeGroupProducts < ActiveRecord::Migration
  def change
    add_reference :products, :size_group, index: true
  end
end
