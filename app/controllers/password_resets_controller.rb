class PasswordResetsController < ApplicationController
  before_action :redirect_if_logged_in, only: [:edit]

  def edit
    @person = Person.find_by(reset_password_token: params[:id])
    unless @person
      redirect_to root_path, alert: 'Invalid or expired token.'
    end
  end

  def update
    @person = Person.find_by(reset_password_token: params[:id])
    if @person && @person.update(person_params)
      @person.clear_reset_password_token!
      redirect_to root_path, notice: 'Password has been updated.'
    else
      render :edit
    end
  end

  private

  def person_params
    params.require(:person).permit(:password, :password_confirmation)
  end

  def redirect_if_logged_in
    if current_person
      redirect_to people_url, alert: 'You are already logged in.'
    end
  end
end