# frozen_string_literal: true

module ConnectorRuby
  module Channels
    class Line < Base
      BASE_URL = "https://api.line.me/v2/bot/message"

      def initialize(channel_access_token: nil)
        @channel_access_token = channel_access_token || ConnectorRuby.configuration.line_channel_access_token
        raise ConfigurationError, "LINE channel_access_token is required" unless @channel_access_token
      end

      def send_text(to:, text:)
        validate_send!(to: to, text: text)
        push_message(to, [{ type: "text", text: text }])
      end

      def send_buttons(to:, text:, buttons:)
        validate_send!(to: to, text: text)
        actions = buttons.map do |btn|
          { type: "postback", label: btn[:title], data: btn[:id] }
        end

        template = {
          type: "template",
          altText: text,
          template: {
            type: "buttons",
            text: text,
            actions: actions
          }
        }
        push_message(to, [template])
      end

      def send_image(to:, url:, caption: nil)
        validate_send!(to: to)
        messages = [{ type: "image", originalContentUrl: url, previewImageUrl: url }]
        messages << { type: "text", text: caption } if caption
        push_message(to, messages)
      end

      def send_flex(to:, alt_text:, contents:)
        validate_send!(to: to)
        flex = {
          type: "flex",
          altText: alt_text,
          contents: contents
        }
        push_message(to, [flex])
      end

      def self.parse_webhook(body)
        data = body.is_a?(String) ? JSON.parse(body) : body

        events = data["events"]
        return nil unless events&.any?

        event_data = events[0]
        case event_data["type"]
        when "message"
          parse_message(event_data)
        when "postback"
          parse_postback(event_data)
        end
      end

      private

      def push_message(to, messages)
        payload = { to: to, messages: messages }
        http_client.post("#{BASE_URL}/push", body: payload, headers: auth_headers)
      end

      def auth_headers
        { "Authorization" => "Bearer #{@channel_access_token}" }
      end

      def validate_send!(to:, text: nil)
        raise ConnectorRuby::Error, "Recipient 'to' cannot be nil or empty" if to.nil? || to.to_s.strip.empty?
        if text
          raise ConnectorRuby::Error, "Text cannot be nil or empty" if text.nil? || text.to_s.strip.empty?
          raise ConnectorRuby::Error, "Text exceeds 5000 character limit" if text.length > 5000
        end
      end

      def self.parse_message(event_data)
        msg = event_data["message"]
        Event.new(
          type: :message,
          channel: :line,
          from: event_data.dig("source", "userId"),
          text: msg["text"],
          timestamp: event_data["timestamp"] ? Time.at(event_data["timestamp"].to_i / 1000) : nil,
          message_id: msg["id"],
          metadata: {
            reply_token: event_data["replyToken"],
            source_type: event_data.dig("source", "type"),
            message_type: msg["type"]
          }
        )
      end

      def self.parse_postback(event_data)
        Event.new(
          type: :callback,
          channel: :line,
          from: event_data.dig("source", "userId"),
          text: event_data.dig("postback", "data"),
          timestamp: event_data["timestamp"] ? Time.at(event_data["timestamp"].to_i / 1000) : nil,
          metadata: {
            reply_token: event_data["replyToken"],
            source_type: event_data.dig("source", "type")
          }
        )
      end
    end
  end
end
