config_file = Rails.root.join('config', "credentials.yml")

if File.exist?(config_file)
  config = YAML.load_file(config_file)

  config.each do |key, value|
    Rails.application.config.x.send("#{key}=", value)
  end

  Rails.application.credentials.secret_key_base = Rails.application.config.x.secret_key_base
end