# frozen_string_literal: true

module ConnectorRuby
  class Event
    attr_reader :type, :channel, :from, :to, :text, :timestamp,
                :message_id, :payload, :metadata

    TYPES = %i[message callback status delivery read reaction].freeze

    def initialize(type:, channel:, from: nil, to: nil, text: nil,
                   timestamp: nil, message_id: nil, payload: nil, metadata: {})
      @type = type
      @channel = channel
      @from = from
      @to = to
      @text = text
      @timestamp = timestamp
      @message_id = message_id
      @payload = payload
      @metadata = metadata
    end

    def message?
      type == :message
    end

    def callback?
      type == :callback
    end

    def status?
      type == :status
    end

    def to_h
      {
        type: @type,
        channel: @channel,
        from: @from,
        to: @to,
        text: @text,
        timestamp: @timestamp,
        message_id: @message_id,
        payload: @payload,
        metadata: @metadata
      }
    end
  end
end
