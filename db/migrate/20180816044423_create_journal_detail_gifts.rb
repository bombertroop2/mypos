class CreateJournalDetailGifts < ActiveRecord::Migration[5.0]
  def change
    create_table :journal_detail_gifts do |t|
      t.references :journal, foreign_key: true
      t.references :product, foreign_key: true
      t.decimal :gross
      t.decimal :gross_after_discount
      t.decimal :discount
      t.decimal :ppn
      t.decimal :nett
      t.timestamps
    end
  end
end
