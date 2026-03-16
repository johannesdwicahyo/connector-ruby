# frozen_string_literal: true

require_relative "test_helper"

class TestLine < Minitest::Test
  def setup
    ConnectorRuby.reset_configuration!
    @client = ConnectorRuby::Line.new(channel_access_token: "test_token")
  end

  def test_send_text
    stub_request(:post, "https://api.line.me/v2/bot/message/push")
      .with(headers: { "Authorization" => "Bearer test_token" })
      .to_return(status: 200, body: '{}')

    result = @client.send_text(to: "U123", text: "Hello!")
    assert_equal({}, result)
  end

  def test_send_buttons
    stub_request(:post, "https://api.line.me/v2/bot/message/push")
      .to_return(status: 200, body: '{}')

    result = @client.send_buttons(
      to: "U123",
      text: "Choose:",
      buttons: [{ id: "opt1", title: "Option 1" }]
    )
    assert_equal({}, result)
  end

  def test_send_image
    stub_request(:post, "https://api.line.me/v2/bot/message/push")
      .to_return(status: 200, body: '{}')

    result = @client.send_image(to: "U123", url: "https://example.com/img.jpg")
    assert_equal({}, result)
  end

  def test_send_flex
    stub_request(:post, "https://api.line.me/v2/bot/message/push")
      .to_return(status: 200, body: '{}')

    result = @client.send_flex(
      to: "U123",
      alt_text: "Flex message",
      contents: { type: "bubble", body: { type: "box", layout: "vertical", contents: [] } }
    )
    assert_equal({}, result)
  end

  def test_parse_webhook_message
    payload = {
      "events" => [{
        "type" => "message",
        "source" => { "userId" => "U123", "type" => "user" },
        "timestamp" => 1700000000000,
        "replyToken" => "reply_token",
        "message" => { "id" => "msg123", "type" => "text", "text" => "Hello" }
      }]
    }

    event = ConnectorRuby::Line.parse_webhook(payload)
    assert event.message?
    assert_equal :line, event.channel
    assert_equal "U123", event.from
    assert_equal "Hello", event.text
    assert_equal "reply_token", event.metadata[:reply_token]
  end

  def test_parse_webhook_postback
    payload = {
      "events" => [{
        "type" => "postback",
        "source" => { "userId" => "U123", "type" => "user" },
        "timestamp" => 1700000000000,
        "replyToken" => "reply_token",
        "postback" => { "data" => "action=buy" }
      }]
    }

    event = ConnectorRuby::Line.parse_webhook(payload)
    assert event.callback?
    assert_equal "action=buy", event.text
  end

  def test_missing_token
    ConnectorRuby.reset_configuration!
    assert_raises(ConnectorRuby::ConfigurationError) do
      ConnectorRuby::Line.new
    end
  end

  def test_empty_recipient_raises
    assert_raises(ConnectorRuby::Error) do
      @client.send_text(to: "", text: "Hello!")
    end
  end
end
