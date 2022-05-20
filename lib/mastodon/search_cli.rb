# frozen_string_literal: true

require_relative '../../config/boot'
require_relative '../../config/environment'
require_relative 'cli_helper'

module Mastodon
  class SearchCLI < Thor
    include CLIHelper

    # Indices are sorted by amount of data to be expected in each, so that
    # smaller indices can go online sooner
    INDICES = [
      AccountsIndex,
      TagsIndex,
      StatusesIndex,
    ].freeze

    option :concurrency, type: :numeric, default: 2, aliases: [:c], desc: 'Workload will be split between this number of threads'
    option :batch_size, type: :numeric, default: 1_000, aliases: [:b], desc: 'Number of records in each batch'
    option :only, type: :array, enum: %w(accounts tags statuses), desc: 'Only process these indices'
    desc 'deploy', 'Create or upgrade Elasticsearch indices and populate them'
    long_desc <<~LONG_DESC
      If Elasticsearch is empty, this command will create the necessary indices
      and then import data from the database into those indices.

      This command will also upgrade indices if the underlying schema has been
      changed since the last run.

      Even if creating or upgrading indices is not necessary, data from the
      database will be imported into the indices.
    LONG_DESC
    def deploy
      if options[:concurrency] < 1
        say('Cannot run with this concurrency setting, must be at least 1', :red)
        exit(1)
      end

      if options[:batch_size] < 1
        say('Cannot run with this batch_size setting, must be at least 1', :red)
        exit(1)
      end

      indices = begin
        if options[:only]
          options[:only].map { |str| "#{str.camelize}Index".constantize }
        else
          INDICES
        end
      end

      progress = ProgressBar.create(total: nil, format: '%t%c/%u |%b%i| %e (%r docs/s)', autofinish: false)

      # First, ensure all indices are created and have the correct
      # structure, so that live data can already be written
      indices.select { |index| index.specification.changed? }.each do |index|
        progress.title = "Upgrading #{index} "
        index.purge
        index.specification.lock!
      end

      reset_connection_pools!

      pool    = Concurrent::FixedThreadPool.new(options[:concurrency])
      added   = 0
      removed = 0

      indices.each do |index|
        progress.title = "Importing #{index} "

        importer = "Importer::#{index.name}Importer".constantize.new(batch_size: options[:batch_size], executor: pool)
        importer.optimize_for_import!

        importer.on_progress { |(indexed, deleted)| progress.progress += indexed + deleted }
        importer.on_failure { |reason| progress.log(pastel.red("Error while importing #{index}: #{reason}")) }

        indexed, deleted = importer.import!

        added   += indexed
        removed += deleted

        importer.optimize_for_search!
      end

      progress.title = ''
      progress.stop

      say("Indexed #{added} records, de-indexed #{removed}", :green, true)
    end
  end
end
