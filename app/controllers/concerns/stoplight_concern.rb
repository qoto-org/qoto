# frozen_string_literal: true

module StoplightConcern
  extend ActiveSupport::Concern

  def object_storage_stoplight(&block)
    Stoplight('object-storage', &block).with_error_handler do |error, handle|
      if error.is_a?(Seahorse::Client::NetworkingError)
        handle.call(error)
      else
        raise error
      end
    end.with_fallback do |error|
      internal_server_error
    end.run
  end
end
