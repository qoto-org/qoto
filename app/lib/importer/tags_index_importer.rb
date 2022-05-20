# frozen_string_literal: true

class Importer::TagsIndexImporter < Importer::BaseImporter
  def import!
    scope.find_in_batches(batch_size: @batch_size) do |records|
      in_work_unit(records) do |tags|
        bulk = Chewy::Index::Import::BulkBuilder.new(index, to_index: tags).bulk_body

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
    TagsIndex
  end

  def scope
    Tag.listable
  end
end
