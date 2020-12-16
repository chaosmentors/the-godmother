class StaticController < ApplicationController
  after_action -> { request.session_options[:skip] = true }

  def home
  end

  def contact
  end

  def privacy
  end

  def imprint
  end

  def setCookie
    cookies[:cookie_eu_consented] = 'true'
    redirect_to request.referrer
  end
  helper_method :setCookie
end
