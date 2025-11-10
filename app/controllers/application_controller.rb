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
    unless registration_open? || godmother?
      redirect_to root_path, alert: "Sorry, registration is closed."
    end
  end

  def registration_open?
    Setting.registration_open? rescue false
  end
  helper_method :registration_open?

  def registration_types
    Setting.registration_types rescue ['mentee', 'mentor']
  end
  helper_method :registration_types

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
    return 'en' unless request.env['HTTP_ACCEPT_LANGUAGE']

    supported_locales = %w[en de]

    # Extract all language codes (e.g., "nl" from "nl-NL", "en" from "en-US")
    accepted_locales = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/([a-z]{2})(?:-[A-Z]{2})?/i).flatten
    supported_locale = accepted_locales.find { |locale| supported_locales.include?(locale.downcase) }

    supported_locale&.downcase || 'en'
  end

  def default_url_options
    { locale: I18n.locale }
  end
end
