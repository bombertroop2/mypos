class CreateCoaCashes < ActiveRecord::Migration[5.0]
  def change
    create_table :coa_cashes do |t|
      t.references :coa, foreign_key: true
      t.date :date
      t.integer :value

      t.timestamps
    end
    add_index :coa_cashes, [:date, :coa_id], unique: true
  end
end
