require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TheGodmother
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Load custom configuration
    config_file = Rails.root.join('config', "credentials.yml")
    if File.exist?(config_file)
      app_conf = YAML.load_file(config_file)

      app_conf.each do |key, value|
        config.x.send("#{key}=", value)
      end

      Rails.application.credentials.secret_key_base = config.x.secret_key_base
    end
    
    # ActionMailer Config
    config.action_mailer.perform_deliveries = true
    config.action_mailer.delivery_method = :smtp

    smtp_settings = config.x.smtp_settings
    config.action_mailer.smtp_settings = {
      address:              smtp_settings["address"],
      port:                 smtp_settings["port"],
      domain:               smtp_settings["domain"],
      user_name:            smtp_settings["user_name"],
      password:             smtp_settings["password"],
      authentication:       smtp_settings["authentication"],
      enable_starttls_auto: smtp_settings["enable_starttls_auto"]
    }
  end
end
