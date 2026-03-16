# frozen_string_literal: true

module ConnectorRuby
  module Channels
    class Slack < Base
      BASE_URL = "https://slack.com/api"

      def initialize(bot_token: nil)
        @bot_token = bot_token || ConnectorRuby.configuration.slack_bot_token
        raise ConfigurationError, "Slack bot_token is required" unless @bot_token
      end

      def send_text(channel:, text:)
        validate_send!(channel: channel, text: text)
        payload = { channel: channel, text: text }
        api_call("chat.postMessage", payload)
      end

      def send_buttons(channel:, text:, buttons:)
        validate_send!(channel: channel, text: text)
        actions = buttons.map do |btn|
          {
            type: "button",
            text: { type: "plain_text", text: btn[:title] },
            action_id: btn[:id],
            value: btn[:id]
          }
        end

        payload = {
          channel: channel,
          text: text,
          blocks: [
            { type: "section", text: { type: "mrkdwn", text: text } },
            { type: "actions", elements: actions }
          ]
        }
        api_call("chat.postMessage", payload)
      end

      def send_image(channel:, url:, caption: nil)
        validate_send!(channel: channel)
        blocks = [
          {
            type: "image",
            image_url: url,
            alt_text: caption || "image"
          }
        ]
        blocks.first[:title] = { type: "plain_text", text: caption } if caption

        payload = { channel: channel, text: caption || "Image", blocks: blocks }
        api_call("chat.postMessage", payload)
      end

      def send_blocks(channel:, text:, blocks:)
        validate_send!(channel: channel)
        payload = { channel: channel, text: text, blocks: blocks }
        api_call("chat.postMessage", payload)
      end

      def self.parse_webhook(body)
        data = body.is_a?(String) ? JSON.parse(body) : body

        # URL verification challenge
        return { challenge: data["challenge"] } if data["type"] == "url_verification"

        event = data["event"]
        return nil unless event

        case event["type"]
        when "message"
          return nil if event["subtype"] # skip bot messages, edits, etc.
          parse_message(event)
        when "app_mention"
          parse_message(event)
        end
      end

      private

      def api_call(method, payload)
        http_client.post("#{BASE_URL}/#{method}", body: payload, headers: auth_headers)
      end

      def auth_headers
        { "Authorization" => "Bearer #{@bot_token}" }
      end

      def validate_send!(channel:, text: nil)
        raise ConnectorRuby::Error, "Recipient 'channel' cannot be nil or empty" if channel.nil? || channel.to_s.strip.empty?
        if text
          raise ConnectorRuby::Error, "Text cannot be nil or empty" if text.nil? || text.to_s.strip.empty?
        end
      end

      def self.parse_message(event)
        Event.new(
          type: :message,
          channel: :slack,
          from: event["user"],
          text: event["text"],
          timestamp: event["ts"] ? Time.at(event["ts"].to_f) : nil,
          message_id: event["ts"],
          metadata: {
            channel_id: event["channel"],
            channel_type: event["channel_type"],
            team: event["team"],
            thread_ts: event["thread_ts"]
          }
        )
      end
    end
  end
end
