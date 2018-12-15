class CreateAccountingJurnalTransctions < ActiveRecord::Migration[5.0]
  def change
    create_table :accounting_jurnal_transctions do |t|
      t.string :type
      t.string :description
      t.integer :model_id
      t.string :model_type

      t.timestamps
    end
  end
end
