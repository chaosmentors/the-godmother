class TicketConfirmationReminderJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 25
  BATCH_DELAY = 30.seconds

  def perform
    # Find all mentees and mentors who:
    # 1. Have verified their email (state != unverified)
    # 2. Have not confirmed their ticket status (has_conference_ticket is nil)
    # 3. Have not been sent a reminder yet (ticket_reminder_sent_at is nil)
    # 4. Are not godmothers only (role != 3)
    people_to_remind = Person.where(has_conference_ticket: nil, ticket_reminder_sent_at: nil)
                             .where.not(role: Person::ROLES.key(:godmother))
                             .where.not(state: Person.state_id(:unverified))

    total_count = people_to_remind.count
    Rails.logger.info "Starting to send ticket confirmation reminders to #{total_count} people in batches of #{BATCH_SIZE}"

    batch_number = 0
    people_to_remind.in_batches(of: BATCH_SIZE).each_with_index do |batch, index|
      batch_number = index + 1
      batch_count = 0

      batch.each do |person|
        # Stagger emails within the batch to spread the load
        wait_time = (index * BATCH_DELAY) + (batch_count * 1.second)

        PersonMailer.with(person: person)
                    .ticket_confirmation_reminder_email
                    .deliver_later(wait: wait_time)

        person.update_column(:ticket_reminder_sent_at, Time.current)
        batch_count += 1
      end

      Rails.logger.info "Batch #{batch_number}: Scheduled #{batch_count} reminder emails (total: #{batch_number * BATCH_SIZE}/#{total_count})"
    end

    Rails.logger.info "Finished scheduling ticket confirmation reminders for #{total_count} people in #{batch_number} batches"
  end
end
