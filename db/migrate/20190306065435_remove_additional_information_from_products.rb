class RemoveAdditionalInformationFromProducts < ActiveRecord::Migration[5.0]
  def change
    remove_column :products, :additional_information, :string
  end
end
