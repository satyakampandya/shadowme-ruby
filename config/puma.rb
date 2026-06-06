# Puma configuration file
threads_count = ENV.fetch("MAX_THREADS") { 5 }.to_i
threads threads_count, threads_count

port ENV.fetch("PORT") { 9292 }
environment ENV.fetch("RACK_ENV") { "development" }

# Use the puma control server in development if needed
workers ENV.fetch("WEB_CONCURRENCY") { 2 }.to_i if ENV["RACK_ENV"] == "production"

preload_app!
