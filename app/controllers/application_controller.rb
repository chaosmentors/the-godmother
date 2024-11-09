class ApplicationController < ActionController::Base
  before_action :set_locale
  before_action :redirect_to_locale_root, if: -> { request.path == '/' }

	private

	def current_person
		@current_person ||= Person.find(session[:person_id]) if session[:person_id]
	end
	helper_method :current_person

	def godmother?
	  if current_person && current_person.isgodmother
      true
    else
      false
    end
  end
  helper_method :godmother?

  def registration_open
    unless Rails.configuration.x.registration_open || godmother?
      redirect_to root_path, alert: "Sorry, registration is closed."
    end
  end

  def require_godmother
    unless godmother?
      flash[:alert] = "You must be logged in."
      session[:last] = request.original_url
      redirect_to controller: 'sessions', action: 'new'
    end
  end

  def set_locale
    I18n.locale = params[:locale] || extract_locale_from_accept_language_header || I18n.default_locale
  end

  def redirect_to_locale_root
    if request.path == '/'
      redirect_to "/#{I18n.locale}/"
    end
  end

  def extract_locale_from_accept_language_header
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first || 'en'
  end

  def default_url_options
    { locale: I18n.locale }
  end
end
