# frozen_string_literal: true

require "time"

module ConnectorRuby
  module Channels
    # LiveChat (livechatinc.com / text.com) Agent API channel.
    #
    # Minimal v0.3.0 surface: send_text + parse_webhook. Buttons, images,
    # and rich events are intentionally deferred to a later release.
    #
    # Authentication uses a Personal Access Token (PAT) with Basic auth.
    # The PAT is typically stored as `base64(account_id:region:pat_value)`,
    # and an `X-Region` header should be sent alongside it. Pass the
    # pre-encoded PAT as `pat:` and the region string as `region:`.
    #
    # Webhook verification is handled separately by
    # `ConnectorRuby::WebhookVerifier.verify_livechat`, because LiveChat
    # authenticates webhooks via a `secret_key` field in the JSON body
    # rather than via HMAC signatures.
    class LiveChat < Base
      BASE_URL = "https://api.livechatinc.com/v3.5/agent/action"

      def initialize(pat: nil, region: nil)
        @pat = pat || ConnectorRuby.configuration.livechat_pat
        @region = region || ConnectorRuby.configuration.livechat_region
        raise ConfigurationError, "LiveChat pat is required" unless @pat
      end

      def send_text(to:, text:)
        validate_send!(to: to, text: text)
        payload = {
          chat_id: to,
          event: { type: "message", text: text }
        }
        http_client.post("#{BASE_URL}/send_event", body: payload, headers: auth_headers)
      end

      def self.parse_webhook(body)
        data = body.is_a?(String) ? JSON.parse(body) : body
        return nil unless data.is_a?(Hash)
        return nil unless data["action"] == "incoming_event"

        payload = data["payload"]
        return nil unless payload.is_a?(Hash)

        event = payload["event"]
        return nil unless event.is_a?(Hash) && event["type"] == "message"

        Event.new(
          type: :message,
          channel: :livechat,
          from: event["author_id"],
          text: event["text"],
          timestamp: parse_timestamp(event["created_at"]),
          message_id: event["id"],
          metadata: {
            chat_id: payload["chat_id"],
            thread_id: payload["thread_id"],
            organization_id: data["organization_id"]
          }
        )
      rescue JSON::ParserError
        nil
      end

      def self.parse_timestamp(value)
        return nil unless value
        Time.parse(value.to_s)
      rescue ArgumentError
        nil
      end

      private

      def auth_headers
        headers = { "Authorization" => "Basic #{@pat}" }
        headers["X-Region"] = @region if @region
        headers
      end

      def validate_send!(to:, text:)
        raise ConnectorRuby::Error, "Recipient 'to' cannot be nil or empty" if to.nil? || to.to_s.strip.empty?
        raise ConnectorRuby::Error, "Text cannot be nil or empty" if text.nil? || text.to_s.strip.empty?
      end
    end
  end
end
