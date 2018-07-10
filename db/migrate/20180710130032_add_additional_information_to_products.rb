class AddAdditionalInformationToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :additional_information, :string
  end
end
