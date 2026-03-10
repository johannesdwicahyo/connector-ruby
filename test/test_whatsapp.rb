# frozen_string_literal: true

require_relative "test_helper"

class TestWhatsApp < Minitest::Test
  def setup
    ConnectorRuby.reset_configuration!
    @client = ConnectorRuby::WhatsApp.new(
      phone_number_id: "123456",
      access_token: "test_token"
    )
  end

  def test_send_text
    stub_request(:post, "https://graph.facebook.com/v21.0/123456/messages")
      .with(
        body: {
          messaging_product: "whatsapp",
          to: "+628123456789",
          type: "text",
          text: { body: "Hello!" }
        }.to_json,
        headers: {
          "Authorization" => "Bearer test_token",
          "Content-Type" => "application/json"
        }
      )
      .to_return(status: 200, body: '{"messages":[{"id":"wamid.123"}]}')

    result = @client.send_text(to: "+628123456789", text: "Hello!")
    assert_equal "wamid.123", result.dig("messages", 0, "id")
  end

  def test_send_buttons
    stub_request(:post, "https://graph.facebook.com/v21.0/123456/messages")
      .to_return(status: 200, body: '{"messages":[{"id":"wamid.456"}]}')

    result = @client.send_buttons(
      to: "+628123456789",
      body: "Choose:",
      buttons: [
        { id: "opt1", title: "Option 1" },
        { id: "opt2", title: "Option 2" }
      ]
    )
    assert_equal "wamid.456", result.dig("messages", 0, "id")
  end

  def test_send_image
    stub_request(:post, "https://graph.facebook.com/v21.0/123456/messages")
      .to_return(status: 200, body: '{"messages":[{"id":"wamid.789"}]}')

    result = @client.send_image(to: "+628123456789", url: "https://example.com/img.jpg")
    assert_equal "wamid.789", result.dig("messages", 0, "id")
  end

  def test_parse_webhook_message
    payload = {
      "entry" => [{
        "changes" => [{
          "value" => {
            "messages" => [{
              "from" => "628123456789",
              "id" => "wamid.abc",
              "timestamp" => "1700000000",
              "type" => "text",
              "text" => { "body" => "Hi there" }
            }],
            "contacts" => [{
              "profile" => { "name" => "John" }
            }]
          }
        }]
      }]
    }

    event = ConnectorRuby::WhatsApp.parse_webhook(payload)
    assert event.message?
    assert_equal :whatsapp, event.channel
    assert_equal "628123456789", event.from
    assert_equal "Hi there", event.text
    assert_equal "wamid.abc", event.message_id
    assert_equal "John", event.metadata[:contact_name]
  end

  def test_parse_webhook_status
    payload = {
      "entry" => [{
        "changes" => [{
          "value" => {
            "statuses" => [{
              "id" => "wamid.xyz",
              "status" => "delivered",
              "timestamp" => "1700000000",
              "recipient_id" => "628123456789"
            }]
          }
        }]
      }]
    }

    event = ConnectorRuby::WhatsApp.parse_webhook(payload)
    assert event.status?
    assert_equal "delivered", event.metadata[:status]
  end

  def test_missing_credentials
    ConnectorRuby.reset_configuration!
    assert_raises(ConnectorRuby::ConfigurationError) do
      ConnectorRuby::WhatsApp.new
    end
  end

  def test_api_error
    stub_request(:post, "https://graph.facebook.com/v21.0/123456/messages")
      .to_return(status: 401, body: '{"error":{"message":"Invalid token"}}')

    assert_raises(ConnectorRuby::AuthenticationError) do
      @client.send_text(to: "+628123456789", text: "Hello!")
    end
  end

  def test_parse_webhook_missing_messages
    payload = {
      "entry" => [{
        "changes" => [{
          "value" => {
            "messages" => []
          }
        }]
      }]
    }

    event = ConnectorRuby::WhatsApp.parse_webhook(payload)
    assert_nil event
  end

  def test_parse_webhook_nil_entry
    payload = {
      "entry" => [nil]
    }

    event = ConnectorRuby::WhatsApp.parse_webhook(payload)
    assert_nil event
  end

  def test_send_text_empty_recipient_raises
    assert_raises(ConnectorRuby::Error) do
      @client.send_text(to: "", text: "Hello!")
    end
  end

  def test_send_text_empty_text_raises
    assert_raises(ConnectorRuby::Error) do
      @client.send_text(to: "+628123456789", text: "")
    end
  end

  def test_send_text_text_too_long_raises
    assert_raises(ConnectorRuby::Error) do
      @client.send_text(to: "+628123456789", text: "a" * 4097)
    end
  end
end
