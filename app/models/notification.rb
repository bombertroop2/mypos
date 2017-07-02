class Notification < ApplicationRecord
  belongs_to :user
  has_many :recipients, dependent: :destroy
  
  after_create_commit { NotificationBroadcastJob.perform_later(self)}
end
