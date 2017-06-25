class Notification < ApplicationRecord
  has_many :recipients, dependent: :destroy
  
  after_create_commit { NotificationBroadcastJob.perform_later(self)}
end
