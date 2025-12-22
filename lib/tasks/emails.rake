namespace :emails do
  desc "Sync emails from IMAP mailbox and match to mentors/mentees"
  task sync: :environment do
    puts "Starting email sync..."

    service = EmailSyncService.new

    unless service.configured?
      puts "Error: IMAP settings not configured in config/credentials.yml"
      exit 1
    end

    result = service.sync

    if result[:error]
      puts "Error: #{result[:error]}"
      exit 1
    end

    puts "Sync completed:"
    puts "  - Synced: #{result[:synced]} emails"
    puts "  - Skipped: #{result[:skipped]} emails (already imported)"

    if result[:errors].any?
      puts "  - Errors: #{result[:errors].count}"
      result[:errors].each do |error|
        puts "    * #{error}"
      end
    end
  end

  desc "Show email sync statistics"
  task stats: :environment do
    total = Email.count
    matched = Email.matched.count
    unmatched = Email.unmatched.count
    inbound = Email.inbound.count
    outbound = Email.outbound.count

    puts "Email Statistics:"
    puts "  Total emails:    #{total}"
    puts "  Matched:         #{matched}"
    puts "  Unmatched:       #{unmatched}"
    puts "  Inbound:         #{inbound}"
    puts "  Outbound:        #{outbound}"
    puts ""
    puts "By mailbox:"
    Email.group(:mailbox).count.each do |mailbox, count|
      puts "  #{mailbox}: #{count}"
    end
  end

  desc "Attempt to re-match unmatched emails to people and fix direction"
  task rematch: :environment do
    unmatched = Email.unmatched
    puts "Attempting to match #{unmatched.count} unmatched emails..."

    matched_count = 0
    direction_fixed_count = 0
    godmother_email = Rails.configuration.x.default_from&.downcase

    unmatched.find_each do |email|
      # Recalculate direction based on current default_from
      correct_direction = if email.from_email&.downcase == godmother_email
        "outbound"
      else
        "inbound"
      end

      # Fix direction if wrong
      if email.direction != correct_direction
        email.update_column(:direction, correct_direction)
        direction_fixed_count += 1
      end

      # Try to match based on correct direction
      person = if correct_direction == "inbound"
        # Match against sender
        Person.find_by("LOWER(email) = ?", email.from_email&.downcase)
      else
        # Match against recipients
        email.to_emails.each do |addr|
          p = Person.find_by("LOWER(email) = ?", addr&.downcase)
          break p if p
        end
      end

      # Handle the case where break returns nil from each block
      person = nil unless person.is_a?(Person)

      if person
        email.update!(person: person)
        matched_count += 1
      end
    end

    puts "Fixed direction on #{direction_fixed_count} emails."
    puts "Matched #{matched_count} emails to people."
  end
end
