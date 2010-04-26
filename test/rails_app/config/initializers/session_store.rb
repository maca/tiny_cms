# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rails_app_session',
  :secret      => '4357a807da4b89877c41ff34394c3be20abd8d264d56c94a205befb4836dfc70053f8b5ab02e1cd2aee7d5a4e34ac49cc7ba328a0923912e743fde4f650f0b32'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
