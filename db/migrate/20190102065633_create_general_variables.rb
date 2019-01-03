class CreateGeneralVariables < ActiveRecord::Migration[5.0]
  def change
    create_table :general_variables do |t|
      t.integer :pieces_per_koli

      t.timestamps
    end
  end
end
