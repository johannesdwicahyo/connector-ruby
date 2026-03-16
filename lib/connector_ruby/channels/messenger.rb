# frozen_string_literal: true

module ConnectorRuby
  module Channels
    class Messenger < Base
      BASE_URL = "https://graph.facebook.com/v21.0/me/messages"

      def initialize(page_access_token: nil)
        @page_access_token = page_access_token || ConnectorRuby.configuration.messenger_page_access_token
        raise ConfigurationError, "Messenger page_access_token is required" unless @page_access_token
      end

      def send_text(to:, text:)
        validate_send!(to: to, text: text)
        payload = {
          recipient: { id: to },
          message: { text: text }
        }
        post_message(payload)
      end

      def send_buttons(to:, text:, buttons:)
        validate_send!(to: to, text: text)
        formatted = buttons.map do |btn|
          { type: "postback", title: btn[:title], payload: btn[:id] }
        end

        payload = {
          recipient: { id: to },
          message: {
            attachment: {
              type: "template",
              payload: {
                template_type: "button",
                text: text,
                buttons: formatted
              }
            }
          }
        }
        post_message(payload)
      end

      def send_image(to:, url:, caption: nil)
        validate_send!(to: to)
        payload = {
          recipient: { id: to },
          message: {
            attachment: {
              type: "image",
              payload: { url: url, is_reusable: true }
            }
          }
        }
        post_message(payload)
      end

      def send_quick_replies(to:, text:, replies:)
        validate_send!(to: to, text: text)
        formatted = replies.map do |r|
          { content_type: "text", title: r[:title], payload: r[:id] }
        end

        payload = {
          recipient: { id: to },
          message: { text: text, quick_replies: formatted }
        }
        post_message(payload)
      end

      def self.parse_webhook(body)
        data = body.is_a?(String) ? JSON.parse(body) : body

        entry = data.dig("entry", 0)
        return nil unless entry

        messaging = entry.dig("messaging", 0)
        return nil unless messaging

        if messaging["message"]
          parse_message(messaging)
        elsif messaging["postback"]
          parse_postback(messaging)
        end
      end

      private

      def post_message(payload)
        http_client.post(BASE_URL, body: payload, headers: auth_headers)
      end

      def auth_headers
        { "Authorization" => "Bearer #{@page_access_token}" }
      end

      def validate_send!(to:, text: nil)
        raise ConnectorRuby::Error, "Recipient 'to' cannot be nil or empty" if to.nil? || to.to_s.strip.empty?
        if text
          raise ConnectorRuby::Error, "Text cannot be nil or empty" if text.nil? || text.to_s.strip.empty?
          raise ConnectorRuby::Error, "Text exceeds 2000 character limit" if text.length > 2000
        end
      end

      def self.parse_message(messaging)
        msg = messaging["message"]
        sender = messaging.dig("sender", "id")

        Event.new(
          type: :message,
          channel: :messenger,
          from: sender,
          to: messaging.dig("recipient", "id"),
          text: msg["text"],
          timestamp: messaging["timestamp"] ? Time.at(messaging["timestamp"].to_i / 1000) : nil,
          message_id: msg["mid"],
          metadata: {
            is_echo: msg["is_echo"],
            quick_reply_payload: msg.dig("quick_reply", "payload")
          }
        )
      end

      def self.parse_postback(messaging)
        postback = messaging["postback"]
        sender = messaging.dig("sender", "id")

        Event.new(
          type: :callback,
          channel: :messenger,
          from: sender,
          to: messaging.dig("recipient", "id"),
          text: postback["payload"],
          timestamp: messaging["timestamp"] ? Time.at(messaging["timestamp"].to_i / 1000) : nil,
          metadata: {
            title: postback["title"]
          }
        )
      end
    end
  end
end
