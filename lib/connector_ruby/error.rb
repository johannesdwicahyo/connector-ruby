# frozen_string_literal: true

module ConnectorRuby
  class Error < StandardError; end
  class ConfigurationError < Error; end

  class ApiError < Error
    attr_reader :status, :body, :channel, :response

    def initialize(message, status: nil, body: nil, channel: nil, response: nil)
      @status = status
      @body = body
      @channel = channel
      @response = response
      super(message)
    end
  end

  class WebhookVerificationError < Error; end
  class RateLimitError < ApiError; end
  class AuthenticationError < ApiError; end
end
