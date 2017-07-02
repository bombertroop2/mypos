class NotificationBroadcastJob < ApplicationJob
  queue_as :default

  def perform(notification)
    # Do something later
    notification.recipients.each do |recipient|
      unnotified_notification_count = Notification.joins(:recipients).where(["recipients.user_id = ? AND notified = ?", recipient.user_id, false]).count("notifications.id")
      ActionCable.server.broadcast "notification_channel_#{recipient.user_id}", notification_id: notification.id, notification: render_notification(notification)
    end
  end
  
  private
 
  def render_counter(counter)
    ApplicationController.renderer.render(partial: 'notifications/counter', locals: { counter: counter })
  end
  
  def render_notification(notification)
    ApplicationController.renderer.render(partial: 'notifications/notification', locals: { notification: notification })
  end
end
