class AddPathToBartenderFileToGeneralVariables < ActiveRecord::Migration[5.0]
  def change
    add_column :general_variables, :path_to_bartender_file, :string, default: ""
  end
end
