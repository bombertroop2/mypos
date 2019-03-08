class AddAdditionalInformationToCostLists < ActiveRecord::Migration[5.0]
  def change
    add_column :cost_lists, :additional_information, :string, default: "NA"
  end
end
