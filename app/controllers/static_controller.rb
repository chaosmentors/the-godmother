class StaticController < ApplicationController
  layout 'public'
  after_action -> { request.session_options[:skip] = true }

  def home
  end

  def contact
  end

  def privacy
  end

  def imprint
  end
  helper_method :setCookie
end
