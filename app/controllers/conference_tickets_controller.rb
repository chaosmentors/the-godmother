class ConferenceTicketsController < ApplicationController
  layout 'public'
  before_action :set_person

  # GET /conference_ticket/:verification_token/edit
  def edit
    unless @person
      redirect_to root_path, alert: t('conference_ticket.invalid_link')
    end
  end

  # PATCH/PUT /conference_ticket/:verification_token
  def update
    unless @person
      redirect_to root_path, alert: t('conference_ticket.invalid_link')
      return
    end

    if @person.group_id.present?
      redirect_to edit_conference_ticket_path(@person.verification_token), alert: t('conference_ticket.cannot_change_in_group')
    elsif @person.update(has_conference_ticket: params[:person][:has_conference_ticket])
      redirect_to edit_conference_ticket_path(@person.verification_token), notice: t('conference_ticket.updated_successfully')
    else
      render :edit
    end
  end

  private

  def set_person
    @person = Person.find_by(verification_token: params[:verification_token])
  end
end
