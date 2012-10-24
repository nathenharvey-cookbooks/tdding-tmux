current_dir = File.dirname(__FILE__)

log_level :warn
log_location STDOUT
cache_options(:path => "#{ENV['HOME']}/.chef/checksums")
cookbook_path ["#{current_dir}/../cookbooks"]
