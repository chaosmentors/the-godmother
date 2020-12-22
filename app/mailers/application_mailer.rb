class ApplicationMailer < ActionMailer::Base
  default from: 'godmother@hackers.org.il'
  layout 'mailer'
  smtp_settings = {
    :address              => "email-smtp.eu-central-1.amazonaws.com",
    :port                 => 587,
    :domain               => "hackers.org.il",
    :user_name            => "AKIAXRBPVYW3RPUECRV5",
    :password             => "BF/so+oNx5eOWy63QSv2Z4XEkZRR7Im3o7dTtxRDEcil",
    :authentication       => "plain",
    :enable_starttls_auto => true
  }
end
