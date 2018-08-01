class CreateCoas < ActiveRecord::Migration[5.0]
  def change
    create_table :coas do |t|
      t.string :code
      t.string :name
      t.references :company, foreign_key: true
      t.string :transaction_type
      t.text :description

      t.timestamps
    end
    add_index :coas, [:company_id, :code], unique: true
    add_index :coas, [:company_id, :transaction_type], unique: true
  end
end
