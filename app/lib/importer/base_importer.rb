# frozen_string_literal: true

# frozen_string_literal: true

class Importer::BaseImporter
  def initialize(batch_size:, executor:)
    @batch_size = batch_size
    @executor   = executor
    @work_units = []
  end

  def on_progress(&block)
    @on_progress = block
  end

  def on_failure(&block)
    @on_failure = block
  end

  def optimize_for_import!
    Chewy.client.indices.put_settings index: index.index_name, settings: { refresh_interval: -1 }
  end

  def optimize_for_search!
    Chewy.client.indices.put_settings index: index.index_name, settings: { refresh_interval: index.settings_hash[:settings][:index][:refresh_interval] }
  end

  def import!
    raise NotImplementedError
  end

  private

  def in_work_unit(*args, &block)
    @work_units << Concurrent::Promises.future_on(@executor, *args, &block)
      .on_fulfillment(&@on_progress)
      .on_rejection(&@on_failure)
  end

  def wait!
    Concurrent::Promises.zip(*@work_units).then { |*values| values.reduce([0, 0]) { |sum, value| [sum[0] + value[0], sum[1] + value[1]] } }.value!
  end

  def index
    raise NotImplementedError
  end
end
