class NotificationsController < ApplicationController
  load_and_authorize_resource
  
  def notify_user
    params[:notification_ids].split(",").each do |notification_id|
      notification = Notification.select(:id).where(id: notification_id).first
      recipient = notification.recipients.select(:id, :notified).where(user_id: current_user.id).first
      recipient.update_attribute(:notified, true)      
    end
    head :ok
  end
end
