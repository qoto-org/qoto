# frozen_string_literal: true

require_relative '../../config/boot'
require_relative '../../config/environment'
require_relative 'cli_helper'

module Mastodon
  class SearchCLI < Thor
    include CLIHelper

    option :concurrency, type: :numeric, default: 2, aliases: [:c]
    desc 'deploy', 'Create or upgrade ElasticSearch indices and populate them'
    long_desc <<~LONG_DESC
      If ElasticSearch is empty, this command will create the necessary indices
      and then import data from the database into those indices.

      This command will also upgrade indices if the underlying schema has been
      changed since the last run.

      Even if creating or upgrading indices is not necessary, data from the
      database will be imported into the indices.
    LONG_DESC
    def deploy
      # Indices are sorted by amount of data to be expected in each, so that
      # smaller indices can go online sooner
      indices = [
        AccountsIndex,
        TagsIndex,
        StatusesIndex,
      ]

      progress = ProgressBar.create(total: nil, format: '%t%c/%u |%b%i| %e')

      # First, ensure all indices are created and have the correct
      # structure, so that live data can already be written
      indices.select { |index| index.specification.changed? }.each do |index|
        progress.title = "Upgrading #{index} "
        index.purge
        index.specification.lock!
        progress.increment
      end

      ActiveRecord::Base.configurations[Rails.env]['pool'] = options[:concurrency] + 1

      pool    = Concurrent::FixedThreadPool.new(options[:concurrency])
      added   = Concurrent::AtomicFixnum.new(0)
      removed = Concurrent::AtomicFixnum.new(0)

      # Now import all the actual data. Mind that unlike chewy:sync, we don't
      # fetch and compare all record IDs from the database and the index to
      # find out which to add and which to remove from the index. Because with
      # potentially millions of rows, the memory footprint of such a calculation
      # is uneconomical. So we only ever add.
      indices.each do |index|
        progress.title = "Importing #{index} "
        futures = []

        index.types.each do |type|
          type.adapter.default_scope.reorder(nil).find_in_batches do |records|
            futures << Concurrent::Future.execute(executor: pool) do
              begin
                grouped_records = nil
                bulk_body       = nil
                index_count     = 0
                delete_count    = 0

                ActiveRecord::Base.connection_pool.with_connection do
                  grouped_records = type.adapter.send(:grouped_objects, records)
                  bulk_body       = Chewy::Type::Import::BulkBuilder.new(type, grouped_records).bulk_body
                end

                index_count  = grouped_records[:index].size  if grouped_records.key?(:index)
                delete_count = grouped_records[:delete].size if grouped_records.key?(:delete)

                # The following is an optimization for statuses specifically, since
                # we want to de-index statuses that cannot be searched by anybody,
                # but can't use Chewy's delete_if logic because it doesn't use
                # crutches and our searchable_by logic depends on them
                if type == StatusesIndex::Status
                  bulk_body.map! do |entry|
                    if entry[:index] && entry.dig(:index, :data, 'searchable_by').blank?
                      index_count  -= 1
                      delete_count += 1

                      { delete: entry[:index].except(:data) }
                    else
                      entry
                    end
                  end
                end

                Chewy::Type::Import::BulkRequest.new(type).perform(bulk_body)

                progress.progress += records.size

                added.increment(index_count)
                removed.increment(delete_count)
              rescue => e
                progress.log pastel.red(e)
              end
            end
          end
        end

        futures.map(&:value)
      end

      progress.title = ''
      progress.finish

      say("Indexed #{added.value} records, de-indexed #{removed.value}", :green, true)
    end
  end
end
