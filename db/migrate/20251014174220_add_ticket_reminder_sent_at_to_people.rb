class AddTicketReminderSentAtToPeople < ActiveRecord::Migration[7.2]
  def change
    add_column :people, :ticket_reminder_sent_at, :datetime
  end
end
