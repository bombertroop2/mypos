class CreateCoaTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :coa_types do |t|
      t.string :code
      t.string :name

      t.timestamps
    end
    add_index :coa_types, :code, unique: true
  end
end
