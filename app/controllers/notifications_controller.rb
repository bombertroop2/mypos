include SmartListing::Helper::ControllerExtensions
class NotificationsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_notification, only: [:show, :destroy]

  def notify_user
    params[:notification_ids].split(",").each do |notification_id|
      notification = Notification.select(:id).where(id: notification_id).first
      recipient = notification.recipients.select(:id, :notified).where(user_id: current_user.id).first
      recipient.update_attribute(:notified, true)      
    end
    head :ok
  end

  # GET /brands/1
  # GET /brands/1.json
  def show
    recipient = @notification.recipients.select(:id, :read).where(user_id: current_user.id).first
    recipient.update notified: true, read: true if recipient
    render partial: 'show'
  end
  
  def index
    recipients = current_user.recipients.where(["read = ?", false])
    recipients.each do |recipient|
      recipient.update notified: true, read: true
    end
    
    like_command = "ILIKE"
    notifications_scope = Notification.select(:id, :event, :body, :created_at).joins(:recipients).where("recipients.user_id = #{current_user.id}")
    notifications_scope = notifications_scope.where(["event #{like_command} ?", "%"+params[:filter]+"%"]).
      or(notifications_scope.where(["body #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    smart_listing_create(:notifications, notifications_scope, partial: 'notifications/listing', default_sort: {:"notifications.created_at" => "desc"})
  end
  
  def destroy
    recipient = @notification.recipients.where(user_id: current_user.id).select(:id).first
    recipient.destroy
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_notification
    @notification = Notification.find(params[:id])
  end
end
