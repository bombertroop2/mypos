namespace :old_session do
  desc "Hapus session lama dari 1 bulan yang lalu ke belakang"
  task remove: :environment do
    cutoff_period = (ENV['SESSION_DAYS_TRIM_THRESHOLD'] || 30).to_i.days.ago
    ActiveRecord::SessionStore::Session.where("updated_at < ?", cutoff_period).delete_all
  end
end
