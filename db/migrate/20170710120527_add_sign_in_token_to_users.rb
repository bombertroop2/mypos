class AddSignInTokenToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :current_sign_in_token, :string
  end
end
