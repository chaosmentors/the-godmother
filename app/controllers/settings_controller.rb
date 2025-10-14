class SettingsController < ApplicationController
  before_action :require_godmother

  def index
    @registration_open = Setting.registration_open? rescue false
    @registration_types = Setting.registration_types rescue ['mentee', 'mentor']
    @pending_ticket_reminders_count = Person.where(has_conference_ticket: nil, ticket_reminder_sent_at: nil)
                                            .where.not(role: Person::ROLES.key(:godmother))
                                            .where.not(state: Person.state_id(:unverified))
                                            .count
  end

  def update
    registration_open = params[:registration_open] == '1'
    registration_types = params[:registration_types] || []

    if registration_open && registration_types.empty?
      flash[:alert] = 'You must select at least one registration type (Mentor or Mentee) when registration is open.'
      redirect_to settings_path
      return
    end

    Setting.set_registration_open(registration_open)
    Setting.set_registration_types(registration_types)

    flash[:notice] = 'Settings updated successfully.'
    redirect_to settings_path
  end

  def send_ticket_reminders
    TicketConfirmationReminderJob.perform_later

    flash[:notice] = 'Ticket confirmation reminders are being sent to users who have not confirmed their ticket status yet.'
    redirect_to settings_path
  end
end
