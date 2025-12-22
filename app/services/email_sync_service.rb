require "net/imap"
require "mail"

class EmailSyncService
  class ImapError < StandardError; end

  def initialize
    @settings = Rails.configuration.x.imap_settings
    @godmother_email = Rails.configuration.x.default_from&.downcase
  end

  def sync
    return { error: "IMAP settings not configured" } unless configured?

    stats = { synced: 0, skipped: 0, errors: [] }

    with_imap_connection do |imap|
      mailboxes.each do |mailbox|
        result = sync_mailbox(imap, mailbox)
        stats[:synced] += result[:synced]
        stats[:skipped] += result[:skipped]
        stats[:errors].concat(result[:errors])
      end
    end

    stats
  rescue Net::IMAP::Error, SocketError, Errno::ECONNREFUSED => e
    { error: "IMAP connection failed: #{e.message}" }
  end

  def configured?
    @settings.present? &&
      @settings["address"].present? &&
      @settings["user_name"].present?
  end

  private

  def mailboxes
    @settings["mailboxes"] || ["INBOX"]
  end

  def with_imap_connection
    imap = Net::IMAP.new(
      @settings["address"],
      port: @settings["port"] || 993,
      ssl: @settings["enable_ssl"] != false
    )

    begin
      imap.login(@settings["user_name"], @settings["password"])
      yield imap
    ensure
      imap.logout rescue nil
      imap.disconnect rescue nil
    end
  end

  def sync_mailbox(imap, mailbox)
    stats = { synced: 0, skipped: 0, errors: [] }

    begin
      imap.select(mailbox)
    rescue Net::IMAP::NoResponseError
      stats[:errors] << "Mailbox '#{mailbox}' not found"
      return stats
    end

    # Fetch all message UIDs
    uids = imap.uid_search(["ALL"])
    return stats if uids.empty?

    # Filter out UIDs we've already processed
    existing_uids = Email.where(mailbox: mailbox).pluck(:imap_uid).map(&:to_s)
    new_uids = uids.map(&:to_s) - existing_uids

    new_uids.each do |uid|
      result = process_message(imap, uid, mailbox)
      case result
      when :synced then stats[:synced] += 1
      when :skipped then stats[:skipped] += 1
      else stats[:errors] << result
      end
    end

    stats
  end

  def process_message(imap, uid, mailbox)
    # Fetch envelope and full message
    data = imap.uid_fetch(uid, ["ENVELOPE", "RFC822"]).first
    return :skipped unless data

    envelope = data.attr["ENVELOPE"]
    return :skipped unless envelope

    message_id = envelope.message_id
    return :skipped if message_id.blank?

    # Skip if already exists (double-check)
    return :skipped if Email.exists?(message_id: message_id)

    from_address = format_address(envelope.from&.first)
    to_addresses = envelope.to&.map { |addr| format_address(addr) }&.compact&.join(", ")

    # Determine direction based on from address
    direction = determine_direction(from_address)

    # Match to person
    person = find_matching_person(from_address, to_addresses, direction)

    # Parse full message with Mail gem to get decoded body
    body_plain, body_html = extract_body_from_message(data.attr["RFC822"])

    Email.create!(
      person: person,
      message_id: message_id,
      in_reply_to: envelope.in_reply_to,
      from_address: from_address,
      to_addresses: to_addresses,
      subject: decode_mime_words(envelope.subject),
      body_plain: body_plain,
      body_html: body_html,
      sent_at: envelope.date ? Time.parse(envelope.date) : nil,
      direction: direction,
      imap_uid: uid.to_s,
      mailbox: mailbox
    )

    :synced
  rescue ActiveRecord::RecordInvalid => e
    "UID #{uid}: #{e.message}"
  rescue StandardError => e
    "UID #{uid}: #{e.class} - #{e.message}"
  end

  def format_address(addr)
    return nil unless addr

    if addr.name.present?
      decoded_name = decode_mime_words(addr.name)
      "#{decoded_name} <#{addr.mailbox}@#{addr.host}>"
    else
      "#{addr.mailbox}@#{addr.host}"
    end
  end

  def determine_direction(from_address)
    return "outbound" if from_address.blank?

    from_email = extract_email(from_address)
    from_email == @godmother_email ? "outbound" : "inbound"
  end

  def find_matching_person(from_address, to_addresses, direction)
    if direction == "inbound"
      # For inbound emails, match against the sender
      email = extract_email(from_address)
      Person.find_by("LOWER(email) = ?", email&.downcase)
    else
      # For outbound emails, match against the recipient(s)
      return nil if to_addresses.blank?

      to_addresses.split(",").each do |addr|
        email = extract_email(addr.strip)
        person = Person.find_by("LOWER(email) = ?", email&.downcase)
        return person if person
      end
      nil
    end
  end

  def extract_email(address)
    return nil if address.blank?

    if address =~ /<([^>]+)>/
      ::Regexp.last_match(1).downcase
    else
      address.strip.downcase
    end
  end

  def extract_body_from_message(raw_message)
    return [nil, nil] if raw_message.blank?

    mail = Mail.new(raw_message)

    # Extract plain text body
    plain_part = if mail.multipart?
      mail.text_part
    elsif mail.content_type&.start_with?("text/plain")
      mail
    end

    body_plain = if plain_part
      decoded = plain_part.decoded
      decoded = decoded.encode("UTF-8", invalid: :replace, undef: :replace, replace: "") rescue decoded
      decoded&.truncate(50_000)
    end

    # Extract HTML body
    html_part = if mail.multipart?
      mail.html_part
    elsif mail.content_type&.start_with?("text/html")
      mail
    end

    body_html = if html_part
      decoded = html_part.decoded
      decoded = decoded.encode("UTF-8", invalid: :replace, undef: :replace, replace: "") rescue decoded
      decoded&.truncate(100_000)
    end

    [body_plain, body_html]
  rescue StandardError => e
    Rails.logger.warn "Failed to parse email body: #{e.message}"
    [nil, nil]
  end

  def decode_mime_words(text)
    return nil if text.blank?

    # Decode MIME encoded-words like "=?UTF-8?Q?Hello?=" or "=?Windows-1252?Q?AW:_Test?="
    Mail::Encodings.value_decode(text)
  rescue StandardError
    text
  end
end
