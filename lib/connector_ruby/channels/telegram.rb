# frozen_string_literal: true

module ConnectorRuby
  module Channels
    class Telegram < Base
      BASE_URL = "https://api.telegram.org"

      def initialize(bot_token: nil)
        @bot_token = bot_token || ConnectorRuby.configuration.telegram_bot_token
        raise ConfigurationError, "Telegram bot_token is required" unless @bot_token
      end

      def send_text(chat_id:, text:, parse_mode: nil)
        validate_send!(chat_id: chat_id, text: text)
        payload = { chat_id: chat_id, text: text }
        payload[:parse_mode] = parse_mode if parse_mode
        api_call("sendMessage", payload)
      end

      def send_buttons(chat_id:, text:, buttons:)
        validate_send!(chat_id: chat_id, text: text)
        keyboard = buttons.map do |btn|
          [{ text: btn[:title], callback_data: btn[:id] }]
        end

        payload = {
          chat_id: chat_id,
          text: text,
          reply_markup: { inline_keyboard: keyboard }
        }
        api_call("sendMessage", payload)
      end

      def send_image(chat_id:, url:, caption: nil)
        validate_send!(chat_id: chat_id)
        payload = { chat_id: chat_id, photo: url }
        payload[:caption] = caption if caption
        api_call("sendPhoto", payload)
      end

      def self.parse_webhook(body)
        data = body.is_a?(String) ? JSON.parse(body) : body

        if data["message"]
          parse_message(data["message"])
        elsif data["callback_query"]
          parse_callback(data["callback_query"])
        end
      end

      private

      def api_call(method, payload)
        url = "#{BASE_URL}/bot#{@bot_token}/#{method}"
        http_client.post(url, body: payload)
      end

      def validate_send!(chat_id:, text: nil)
        raise ConnectorRuby::Error, "Recipient 'chat_id' cannot be nil or empty" if chat_id.nil? || chat_id.to_s.strip.empty?
        if text
          raise ConnectorRuby::Error, "Text cannot be nil or empty" if text.nil? || text.to_s.strip.empty?
          raise ConnectorRuby::Error, "Text exceeds 4096 character limit" if text.length > 4096
        end
      end

      def self.parse_message(msg)
        return nil unless msg
        Event.new(
          type: :message,
          channel: :telegram,
          from: msg.dig("from", "id")&.to_s,
          text: msg["text"],
          timestamp: msg["date"] ? Time.at(msg["date"]) : nil,
          message_id: msg["message_id"]&.to_s,
          metadata: {
            chat_id: msg.dig("chat", "id"),
            chat_type: msg.dig("chat", "type"),
            from_username: msg.dig("from", "username"),
            from_first_name: msg.dig("from", "first_name")
          }
        )
      end

      def self.parse_callback(callback)
        return nil unless callback
        Event.new(
          type: :callback,
          channel: :telegram,
          from: callback.dig("from", "id")&.to_s,
          text: callback["data"],
          message_id: callback["id"],
          metadata: {
            chat_id: callback.dig("message", "chat", "id"),
            original_message_id: callback.dig("message", "message_id"),
            from_username: callback.dig("from", "username")
          }
        )
      end
    end
  end
end
