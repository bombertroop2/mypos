class AddAdditionalInformationToPriceLists < ActiveRecord::Migration[5.0]
  def change
    add_column :price_lists, :additional_information, :string, default: "NA"
  end
end
