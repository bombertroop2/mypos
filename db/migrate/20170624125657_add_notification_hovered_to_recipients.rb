class AddNotificationHoveredToRecipients < ActiveRecord::Migration[5.0]
  def change
    add_column :recipients, :notification_hovered, :boolean, default: false
  end
end
