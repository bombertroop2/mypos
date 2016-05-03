class RemoveEffectiveDateAndCostFromProducts < ActiveRecord::Migration
  def change
    remove_column :products, :effective_date, :date
    remove_column :products, :cost, :decimal
  end
end
