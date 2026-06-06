require_relative 'app'

# Freeze the Roda app in production/testing to optimize routing performance
App.freeze if ENV['RACK_ENV'] == 'production'

run App
