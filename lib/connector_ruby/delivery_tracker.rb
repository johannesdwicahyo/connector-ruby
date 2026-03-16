# frozen_string_literal: true

module ConnectorRuby
  class DeliveryTracker
    attr_reader :entries

    def initialize
      @entries = {}
      @callbacks = Hash.new { |h, k| h[k] = [] }
    end

    def track(message_id, metadata: {})
      @entries[message_id] = {
        status: :sent,
        sent_at: Time.now,
        metadata: metadata,
        history: [{ status: :sent, at: Time.now }]
      }
    end

    def update(message_id, status:)
      entry = @entries[message_id]
      return nil unless entry

      entry[:status] = status.to_sym
      entry[:history] << { status: status.to_sym, at: Time.now }

      fire(status.to_sym, message_id, entry)
      entry
    end

    def status(message_id)
      @entries.dig(message_id, :status)
    end

    def on(status, &block)
      @callbacks[status.to_sym] << block
    end

    def pending
      @entries.select { |_, v| v[:status] == :sent }
    end

    def delivered
      @entries.select { |_, v| v[:status] == :delivered }
    end

    def read
      @entries.select { |_, v| v[:status] == :read }
    end

    private

    def fire(status, message_id, entry)
      @callbacks[status].each { |cb| cb.call(message_id, entry) }
    end
  end
end
