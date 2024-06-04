# frozen_string_literal: true

module LenderLeadsWebhook
  class CasheWorker
    include Sidekiq::Worker

    sidekiq_options queue: :cron

    STATUSES = %w[ACEEPTED APPROVED ELIGIBLE INPROGRESS].freeze

    def perform(_params={})
      records = LoanProfile.where(lender_code: "CASHE", status: STATUSES)
      records.each do |record|
        Cashe.new.fetch_status(record.external_loan_id)
      end
    end
  end
end
