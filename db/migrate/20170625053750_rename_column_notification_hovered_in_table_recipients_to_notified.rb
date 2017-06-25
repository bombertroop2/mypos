class RenameColumnNotificationHoveredInTableRecipientsToNotified < ActiveRecord::Migration[5.0]
  def change
    rename_column :recipients, :notification_hovered, :notified
  end
end
