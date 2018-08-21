class AddCoaTypeIdToCoa < ActiveRecord::Migration[5.0]
  def change
    add_column :coas, :group, :string
    add_reference :coas, :coa_type, foreign_key: true
  end
end
