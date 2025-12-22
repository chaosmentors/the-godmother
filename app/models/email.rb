class Email < ApplicationRecord
  belongs_to :person, optional: true

  enum :direction, { inbound: "inbound", outbound: "outbound" }

  validates :message_id, presence: true, uniqueness: true
  validates :from_address, presence: true

  scope :matched, -> { where.not(person_id: nil) }
  scope :unmatched, -> { where(person_id: nil) }
  scope :recent, -> { order(sent_at: :desc) }

  def matched?
    person_id.present?
  end

  def from_email
    extract_email(from_address)
  end

  def to_emails
    return [] if to_addresses.blank?

    to_addresses.split(",").map { |addr| extract_email(addr.strip) }.compact
  end

  private

  def extract_email(address)
    return nil if address.blank?

    if address =~ /<([^>]+)>/
      ::Regexp.last_match(1).downcase
    else
      address.strip.downcase
    end
  end
end
