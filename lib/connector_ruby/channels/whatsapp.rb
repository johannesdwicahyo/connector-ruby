# frozen_string_literal: true

module ConnectorRuby
  module Channels
    class WhatsApp < Base
      BASE_URL = "https://graph.facebook.com/v21.0"

      def initialize(phone_number_id: nil, access_token: nil)
        @phone_number_id = phone_number_id || ConnectorRuby.configuration.whatsapp_phone_number_id
        @access_token = access_token || ConnectorRuby.configuration.whatsapp_access_token

        raise ConfigurationError, "WhatsApp phone_number_id is required" unless @phone_number_id
        raise ConfigurationError, "WhatsApp access_token is required" unless @access_token
      end

      def send_text(to:, text:)
        validate_send!(to: to, text: text)
        payload = {
          messaging_product: "whatsapp",
          to: to,
          type: "text",
          text: { body: text }
        }
        post_message(payload)
      end

      def send_buttons(to:, body:, buttons:)
        validate_send!(to: to, text: body)
        formatted_buttons = buttons.map do |btn|
          { type: "reply", reply: { id: btn[:id], title: btn[:title] } }
        end

        payload = {
          messaging_product: "whatsapp",
          to: to,
          type: "interactive",
          interactive: {
            type: "button",
            body: { text: body },
            action: { buttons: formatted_buttons }
          }
        }
        post_message(payload)
      end

      def send_image(to:, url:, caption: nil)
        validate_send!(to: to)
        image = { link: url }
        image[:caption] = caption if caption

        payload = {
          messaging_product: "whatsapp",
          to: to,
          type: "image",
          image: image
        }
        post_message(payload)
      end

      def self.parse_webhook(body, signature: nil)
        data = body.is_a?(String) ? JSON.parse(body) : body

        entry = data.dig("entry", 0)
        return nil unless entry

        changes = entry.dig("changes", 0)
        return nil unless changes

        value = changes["value"]
        return nil unless value

        if value["messages"]&.any?
          parse_message(value)
        elsif value["statuses"]&.any?
          parse_status(value)
        end
      end

      private

      def post_message(payload)
        url = "#{BASE_URL}/#{@phone_number_id}/messages"
        http_client.post(url, body: payload, headers: auth_headers)
      end

      def auth_headers
        { "Authorization" => "Bearer #{@access_token}" }
      end

      def validate_send!(to:, text: nil)
        raise ConnectorRuby::Error, "Recipient 'to' cannot be nil or empty" if to.nil? || to.to_s.strip.empty?
        if text
          raise ConnectorRuby::Error, "Text cannot be nil or empty" if text.nil? || text.to_s.strip.empty?
          raise ConnectorRuby::Error, "Text exceeds 4096 character limit" if text.length > 4096
        end
      end

      def self.parse_message(value)
        return nil unless value["messages"]&.any?
        msg = value["messages"][0]
        contact = value.dig("contacts", 0)

        Event.new(
          type: :message,
          channel: :whatsapp,
          from: msg["from"],
          text: msg.dig("text", "body"),
          timestamp: msg["timestamp"] ? Time.at(msg["timestamp"].to_i) : nil,
          message_id: msg["id"],
          metadata: {
            contact_name: contact&.dig("profile", "name"),
            message_type: msg["type"]
          }
        )
      end

      def self.parse_status(value)
        return nil unless value["statuses"]&.any?
        status = value["statuses"][0]

        Event.new(
          type: :status,
          channel: :whatsapp,
          to: status["recipient_id"],
          message_id: status["id"],
          metadata: {
            status: status["status"],
            timestamp: status["timestamp"]
          }
        )
      end
    end
  end
end
