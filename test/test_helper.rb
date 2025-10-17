ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionDispatch::IntegrationTest
  # Helper method to create and login as a godmother
  def login_as_godmother(person)
    post sessions_url, params: { session: { email: person.email, password: 'test_password_123456' } }
    assert_response :redirect
  end

  # Helper to get the captcha answer for registration
  def get_captcha_answer(question_number)
    I18n.t('captcha_questions')[question_number.to_i][:answer]
  end
end
