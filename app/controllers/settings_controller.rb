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

  def export_csv
    # Get all mentees and mentors (exclude godmothers)
    people = Person.where(role: [Person::ROLES.key(:mentee), Person::ROLES.key(:mentor)])
                   .order(:created_at)

    csv_string = generate_people_csv(people)

    send_data csv_string,
              filename: "mentees_mentors_export_#{Date.today.strftime('%Y%m%d')}.csv",
              type: 'text/csv'
  end

  def export_matchable_csv
    # Get all mentees and mentors that are matchable:
    # - In waiting state
    # - Have confirmed conference ticket
    people = Person.where(role: [Person::ROLES.key(:mentee), Person::ROLES.key(:mentor)])
                   .where(state: Person.state_id(:waiting))
                   .where(has_conference_ticket: true)
                   .order(role: :desc, created_at: :asc)

    csv_string = generate_people_csv(people)

    send_data csv_string,
              filename: "matchable_participants_export_#{Date.today.strftime('%Y%m%d')}.csv",
              type: 'text/csv'
  end

  private

  def generate_people_csv(people)
    require 'csv'

    CSV.generate(headers: true) do |csv|
      # Define headers - all person attributes plus computed fields
      csv << [
        'ID',
        'Random ID',
        'Name',
        'Pronoun',
        'Email',
        'About',
        'Role',
        'State',
        'Group Label',
        'Tags',
        'Has Conference Ticket',
        'Ticket Reminder Sent At',
        'Validated At',
        'Created At',
        'Updated At'
      ]

      # Add each person's data
      people.each do |person|
        csv << [
          person.id,
          person.random_id,
          person.name,
          person.pronoun,
          person.email,
          person.about,
          person.role_name,
          person.state_name,
          person.group&.label,
          person.tag_list,
          person.has_conference_ticket,
          person.ticket_reminder_sent_at,
          person.validated_at,
          person.created_at,
          person.updated_at
        ]
      end
    end
  end
end
