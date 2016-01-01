class CreateSizes < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists? 'sizes'
      create_table :sizes do |t|
        t.references :size_group, index: true, foreign_key: true
        t.string :size

        t.timestamps null: false
      end

    end
  end
end
