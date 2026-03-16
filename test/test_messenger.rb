# frozen_string_literal: true

require_relative "test_helper"

class TestMessenger < Minitest::Test
  def setup
    ConnectorRuby.reset_configuration!
    @client = ConnectorRuby::Messenger.new(page_access_token: "test_token")
  end

  def test_send_text
    stub_request(:post, "https://graph.facebook.com/v21.0/me/messages")
      .with(headers: { "Authorization" => "Bearer test_token" })
      .to_return(status: 200, body: '{"recipient_id":"123","message_id":"mid.abc"}')

    result = @client.send_text(to: "123", text: "Hello!")
    assert_equal "mid.abc", result["message_id"]
  end

  def test_send_buttons
    stub_request(:post, "https://graph.facebook.com/v21.0/me/messages")
      .to_return(status: 200, body: '{"recipient_id":"123","message_id":"mid.btn"}')

    result = @client.send_buttons(
      to: "123",
      text: "Choose:",
      buttons: [{ id: "opt1", title: "Option 1" }]
    )
    assert_equal "mid.btn", result["message_id"]
  end

  def test_send_image
    stub_request(:post, "https://graph.facebook.com/v21.0/me/messages")
      .to_return(status: 200, body: '{"recipient_id":"123","message_id":"mid.img"}')

    result = @client.send_image(to: "123", url: "https://example.com/img.jpg")
    assert_equal "mid.img", result["message_id"]
  end

  def test_send_quick_replies
    stub_request(:post, "https://graph.facebook.com/v21.0/me/messages")
      .with { |req| JSON.parse(req.body).dig("message", "quick_replies")&.any? }
      .to_return(status: 200, body: '{"message_id":"mid.qr"}')

    result = @client.send_quick_replies(
      to: "123",
      text: "Choose:",
      replies: [{ id: "yes", title: "Yes" }, { id: "no", title: "No" }]
    )
    assert_equal "mid.qr", result["message_id"]
  end

  def test_parse_webhook_message
    payload = {
      "entry" => [{
        "messaging" => [{
          "sender" => { "id" => "user123" },
          "recipient" => { "id" => "page456" },
          "timestamp" => 1700000000000,
          "message" => { "mid" => "mid.abc", "text" => "Hello" }
        }]
      }]
    }

    event = ConnectorRuby::Messenger.parse_webhook(payload)
    assert event.message?
    assert_equal :messenger, event.channel
    assert_equal "user123", event.from
    assert_equal "Hello", event.text
    assert_equal "mid.abc", event.message_id
  end

  def test_parse_webhook_postback
    payload = {
      "entry" => [{
        "messaging" => [{
          "sender" => { "id" => "user123" },
          "recipient" => { "id" => "page456" },
          "timestamp" => 1700000000000,
          "postback" => { "title" => "Get Started", "payload" => "GET_STARTED" }
        }]
      }]
    }

    event = ConnectorRuby::Messenger.parse_webhook(payload)
    assert event.callback?
    assert_equal "GET_STARTED", event.text
  end

  def test_missing_token
    ConnectorRuby.reset_configuration!
    assert_raises(ConnectorRuby::ConfigurationError) do
      ConnectorRuby::Messenger.new
    end
  end

  def test_empty_recipient_raises
    assert_raises(ConnectorRuby::Error) do
      @client.send_text(to: "", text: "Hello!")
    end
  end

  def test_text_too_long_raises
    assert_raises(ConnectorRuby::Error) do
      @client.send_text(to: "123", text: "a" * 2001)
    end
  end
end
