# frozen_string_literal: true

require_relative "test_helper"

class TestTelegram < Minitest::Test
  def setup
    ConnectorRuby.reset_configuration!
    @client = ConnectorRuby::Telegram.new(bot_token: "123:ABC")
  end

  def test_send_text
    stub_request(:post, "https://api.telegram.org/bot123:ABC/sendMessage")
      .with(
        body: { chat_id: 12345, text: "Hello!" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      .to_return(status: 200, body: '{"ok":true,"result":{"message_id":1}}')

    result = @client.send_text(chat_id: 12345, text: "Hello!")
    assert result["ok"]
  end

  def test_send_buttons
    stub_request(:post, "https://api.telegram.org/bot123:ABC/sendMessage")
      .to_return(status: 200, body: '{"ok":true,"result":{"message_id":2}}')

    result = @client.send_buttons(
      chat_id: 12345,
      text: "Choose:",
      buttons: [
        { id: "opt1", title: "Option 1" },
        { id: "opt2", title: "Option 2" }
      ]
    )
    assert result["ok"]
  end

  def test_send_image
    stub_request(:post, "https://api.telegram.org/bot123:ABC/sendPhoto")
      .to_return(status: 200, body: '{"ok":true,"result":{"message_id":3}}')

    result = @client.send_image(chat_id: 12345, url: "https://example.com/img.jpg")
    assert result["ok"]
  end

  def test_parse_webhook_message
    payload = {
      "message" => {
        "message_id" => 123,
        "from" => { "id" => 456, "username" => "johnd", "first_name" => "John" },
        "chat" => { "id" => 789, "type" => "private" },
        "date" => 1700000000,
        "text" => "Hello bot"
      }
    }

    event = ConnectorRuby::Telegram.parse_webhook(payload)
    assert event.message?
    assert_equal :telegram, event.channel
    assert_equal "456", event.from
    assert_equal "Hello bot", event.text
    assert_equal 789, event.metadata[:chat_id]
    assert_equal "johnd", event.metadata[:from_username]
  end

  def test_parse_webhook_callback
    payload = {
      "callback_query" => {
        "id" => "cb123",
        "from" => { "id" => 456, "username" => "johnd" },
        "data" => "opt1",
        "message" => {
          "message_id" => 123,
          "chat" => { "id" => 789 }
        }
      }
    }

    event = ConnectorRuby::Telegram.parse_webhook(payload)
    assert event.callback?
    assert_equal :telegram, event.channel
    assert_equal "opt1", event.text
    assert_equal 789, event.metadata[:chat_id]
  end

  def test_missing_bot_token
    ConnectorRuby.reset_configuration!
    assert_raises(ConnectorRuby::ConfigurationError) do
      ConnectorRuby::Telegram.new
    end
  end

  def test_parse_webhook_nil_message
    payload = { "message" => nil }

    event = ConnectorRuby::Telegram.parse_webhook(payload)
    assert_nil event
  end

  def test_send_text_empty_chat_id_raises
    assert_raises(ConnectorRuby::Error) do
      @client.send_text(chat_id: "", text: "Hello!")
    end
  end

  def test_send_text_empty_text_raises
    assert_raises(ConnectorRuby::Error) do
      @client.send_text(chat_id: 12345, text: "")
    end
  end
end
