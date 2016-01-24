class AddIndexToCommonFields < ActiveRecord::Migration
  def change
    add_index :common_fields, [:code, :type], :unique => true
  end
end
