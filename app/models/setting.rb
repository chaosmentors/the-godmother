class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.get(key)
    find_by(key: key)&.value
  end

  def self.set(key, value)
    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    setting.save
  end

  def self.registration_open?
    get('registration_open') == 'true'
  end

  def self.set_registration_open(value)
    set('registration_open', value)
  end

  def self.registration_types
    value = get('registration_types')
    return ['mentee', 'mentor'] if value.nil? || value.empty?
    JSON.parse(value) rescue ['mentee', 'mentor']
  end

  def self.set_registration_types(types)
    types = types.reject(&:blank?) if types.is_a?(Array)
    set('registration_types', types.to_json)
  end
end
