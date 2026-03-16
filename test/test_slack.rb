# frozen_string_literal: true

require_relative "test_helper"

class TestSlack < Minitest::Test
  def setup
    ConnectorRuby.reset_configuration!
    @client = ConnectorRuby::Slack.new(bot_token: "xoxb-test")
  end

  def test_send_text
    stub_request(:post, "https://slack.com/api/chat.postMessage")
      .with(headers: { "Authorization" => "Bearer xoxb-test" })
      .to_return(status: 200, body: '{"ok":true,"ts":"1234.5678"}')

    result = @client.send_text(channel: "C123", text: "Hello!")
    assert result["ok"]
  end

  def test_send_buttons
    stub_request(:post, "https://slack.com/api/chat.postMessage")
      .to_return(status: 200, body: '{"ok":true,"ts":"1234.5679"}')

    result = @client.send_buttons(
      channel: "C123",
      text: "Choose:",
      buttons: [{ id: "opt1", title: "Option 1" }]
    )
    assert result["ok"]
  end

  def test_send_image
    stub_request(:post, "https://slack.com/api/chat.postMessage")
      .to_return(status: 200, body: '{"ok":true}')

    result = @client.send_image(channel: "C123", url: "https://example.com/img.jpg", caption: "A photo")
    assert result["ok"]
  end

  def test_send_blocks
    stub_request(:post, "https://slack.com/api/chat.postMessage")
      .to_return(status: 200, body: '{"ok":true}')

    result = @client.send_blocks(
      channel: "C123",
      text: "Fallback",
      blocks: [{ type: "section", text: { type: "mrkdwn", text: "*Bold*" } }]
    )
    assert result["ok"]
  end

  def test_parse_webhook_message
    payload = {
      "event" => {
        "type" => "message",
        "user" => "U123",
        "text" => "Hello bot",
        "ts" => "1700000000.000000",
        "channel" => "C456",
        "channel_type" => "channel",
        "team" => "T789"
      }
    }

    event = ConnectorRuby::Slack.parse_webhook(payload)
    assert event.message?
    assert_equal :slack, event.channel
    assert_equal "U123", event.from
    assert_equal "Hello bot", event.text
    assert_equal "C456", event.metadata[:channel_id]
  end

  def test_parse_webhook_url_verification
    payload = { "type" => "url_verification", "challenge" => "abc123" }
    result = ConnectorRuby::Slack.parse_webhook(payload)
    assert_equal "abc123", result[:challenge]
  end

  def test_parse_webhook_skips_bot_messages
    payload = {
      "event" => { "type" => "message", "subtype" => "bot_message", "text" => "bot" }
    }
    event = ConnectorRuby::Slack.parse_webhook(payload)
    assert_nil event
  end

  def test_missing_token
    ConnectorRuby.reset_configuration!
    assert_raises(ConnectorRuby::ConfigurationError) do
      ConnectorRuby::Slack.new
    end
  end

  def test_empty_channel_raises
    assert_raises(ConnectorRuby::Error) do
      @client.send_text(channel: "", text: "Hello!")
    end
  end
end
