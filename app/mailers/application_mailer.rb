class ApplicationMailer < ActionMailer::Base
  default from: Rails.configuration.x.default_from
  layout 'mailer'
end
