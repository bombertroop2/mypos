require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Posapp
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.time_zone = 'Asia/Makassar'
    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    
    Warden::Manager.after_authentication do |user, auth, opts|
      #auth.cookies - to access cookie
      token = Devise.friendly_token
      user.update_attribute :current_sign_in_token, token
      #session
      auth.env['rack.session'][:sign_in_token] = token
    end
   
    Warden::Manager.before_logout do |user, auth, opts|
      auth.env['rack.session'].delete :sign_in_token
    end
  end
end
