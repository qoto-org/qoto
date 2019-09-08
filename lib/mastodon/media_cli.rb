# frozen_string_literal: true

require_relative '../../config/boot'
require_relative '../../config/environment'
require_relative 'cli_helper'

module Mastodon
  class MediaCLI < Thor
    include ActionView::Helpers::NumberHelper

    def self.exit_on_failure?
      true
    end

    option :days, type: :numeric, default: 7, aliases: [:d]
    option :concurrency, type: :numeric, default: 5, aliases: [:c]
    option :verbose, type: :boolean, default: false, aliases: [:v]
    option :dry_run, type: :boolean, default: false
    desc 'remove', 'Remove remote media files'
    long_desc <<-DESC
      Removes locally cached copies of media attachments from other servers.

      The --days option specifies how old media attachments have to be before
      they are removed. It defaults to 7 days.

      The --concurrency option specifies how many media attachments to process
      at the same time. It defaults to 5.

      With the --dry-run option, no work will be done.

      With the --verbose option the IDs of the media attachments will be printed.
    DESC
    def remove
      time_ago = options[:days].days.ago
      dry_run  = options[:dry_run] ? '(DRY RUN)' : ''

      processed, aggregate = parallelize_with_progress(MediaAttachment.cached.where('created_at < ?', time_ago)) do |media_attachment|
        next if media_attachment.file.blank?

        size = media_attachment.file_file_size

        unless options[:dry_run]
          media_attachment.file.destroy
          media_attachment.save
        end

        size
      end

      say("Removed #{processed} media attachments (approx. #{number_to_human_size(aggregate)}) #{dry_run}", :green, true)
    end

    private

    def parallelize_with_progress(scope)
      ActiveRecord::Base.configurations[Rails.env]['pool'] = options[:concurrency]

      progress  = ProgressBar.create(total: scope.count, format: '%c/%u |%b%i| %e')
      pool      = Concurrent::FixedThreadPool.new(options[:concurrency])
      futures   = []
      aggregate = 0

      scope.find_each do |item|
        progress.total = futures.size + 1 if progress.total < futures.size + 1

        futures << Concurrent::Future.execute(executor: pool) do
          begin
            progress.log("Processing #{item.id}") if options[:verbose]
            aggregate += yield(item) || 0
          rescue => e
            progress.log pastel.red("Error processing #{item.id}: #{e}")
          ensure
            progress.increment
          end
        end
      end

      futures.map(&:value)
      progress.finish

      [futures.size, aggregate]
    end

    def pastel
      @pastel ||= Pastel.new
    end
  end
end
