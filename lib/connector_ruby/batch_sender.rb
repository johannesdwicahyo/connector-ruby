# frozen_string_literal: true

module ConnectorRuby
  class BatchSender
    RATE_LIMITS = {
      whatsapp: { messages_per_second: 80 },
      telegram: { messages_per_second: 30 },
      messenger: { messages_per_second: 200 },
      line: { messages_per_second: 100 },
      slack: { messages_per_second: 1 }
    }.freeze

    def initialize(channel:)
      @channel = channel
      @results = []
      @errors = []
    end

    def send_batch(messages)
      rate = rate_limit_for(@channel)
      delay = 1.0 / rate

      messages.each_with_index do |msg, i|
        sleep(delay) if i > 0
        begin
          result = yield msg
          @results << { index: i, status: :sent, result: result }
        rescue => e
          @errors << { index: i, status: :failed, error: e.message }
        end
      end

      { sent: @results, failed: @errors, total: messages.size }
    end

    private

    def rate_limit_for(channel)
      channel_sym = channel.class.name.split("::").last.downcase.to_sym
      config = RATE_LIMITS[channel_sym] || { messages_per_second: 10 }
      config[:messages_per_second]
    end
  end
end
