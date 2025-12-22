class EmailSyncJob < ApplicationJob
  queue_as :default

  def perform
    service = EmailSyncService.new

    unless service.configured?
      Rails.logger.warn "EmailSyncJob: IMAP settings not configured, skipping sync"
      return
    end

    Rails.logger.info "EmailSyncJob: Starting email sync from IMAP"

    result = service.sync

    if result[:error]
      Rails.logger.error "EmailSyncJob: #{result[:error]}"
      return
    end

    Rails.logger.info "EmailSyncJob: Synced #{result[:synced]} emails, skipped #{result[:skipped]}"

    if result[:errors].any?
      Rails.logger.warn "EmailSyncJob: #{result[:errors].count} errors occurred:"
      result[:errors].each { |error| Rails.logger.warn "  - #{error}" }
    end
  end
end
