require "#{Rails.root}/config/webistrano_config"

if WebistranoConfig[:authentication_method] == :cas
  cas_options = YAML::load_file(Rails.root + '/config/cas.xml')
  CASClient::Frameworks::Rails::Filter.configure(cas_options[Rails.env.to_s])
end

WEBISTRANO_VERSION = '1.6'

ActionMailer::Base.delivery_method = WebistranoConfig[:smtp_delivery_method]
ActionMailer::Base.smtp_settings = WebistranoConfig[:smtp_settings]

#ActiveSupport::Notification.webistrano_sender_address = WebistranoConfig[:webistrano_sender_address]

Webistrano::Application.config.middleware.use ExceptionNotification::Rack,
  :email => {
    # :email_prefix => "[Whatever] ",
    :sender_address => WebistranoConfig[:exception_sender_address],
    :exception_recipients => WebistranoConfig[:exception_recipients]
  }
