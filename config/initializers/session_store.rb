# Be sure to restart your server when you modify this file.

#Rails.application.config.session_store :cookie_store, key: '_posapp_session'
Rails.application.config.session_store :active_record_store, :key => '_posapp_session'
