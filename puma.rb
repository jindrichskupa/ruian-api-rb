root = "#{Dir.getwd}"
environment 'production'

daemonize false

bind 'tcp://0.0.0.0:8080'
bind "unix://#{root}/tmp/puma/socket"
pidfile "#{root}/tmp/puma/pid"
state_path "#{root}/tmp/puma/state"
rackup "#{root}/config.ru"

threads 4, 8

activate_control_app
