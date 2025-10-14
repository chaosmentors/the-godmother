class SettingsController < ApplicationController
  before_action :require_godmother

  def index
    @registration_open = Setting.registration_open? rescue false
  end

  def update
    if params[:registration_open].present?
      Setting.set_registration_open(params[:registration_open] == '1')
      flash[:notice] = 'Settings updated successfully.'
    else
      Setting.set_registration_open(false)
      flash[:notice] = 'Settings updated successfully.'
    end

    redirect_to settings_path
  end
end
