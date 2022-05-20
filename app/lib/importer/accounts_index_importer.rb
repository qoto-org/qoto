# frozen_string_literal: true

class Importer::AccountsIndexImporter < Importer::BaseImporter
  def import!
    scope.find_in_batches(batch_size: @batch_size) do |records|
      in_work_unit(records) do |accounts|
        bulk = Chewy::Index::Import::BulkBuilder.new(index, to_index: accounts).bulk_body

        indexed = bulk.select { |entry| entry[:index] }.size
        deleted = bulk.select { |entry| entry[:delete] }.size

        Chewy::Index::Import::BulkRequest.new(index).perform(bulk)

        [indexed, deleted].tap do |result|
          yield result if block_given?
        end
      end
    end

    wait!
  end

  private

  def index
    AccountsIndex
  end

  def scope
    Account.searchable.includes(:account_stat)
  end
end
