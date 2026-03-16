# frozen_string_literal: true

require_relative "test_helper"

# --- New WhatsApp message types ---

class TestWhatsAppNewTypes < Minitest::Test
  def setup
    ConnectorRuby.reset_configuration!
    @client = ConnectorRuby::WhatsApp.new(phone_number_id: "123456", access_token: "test_token")
    stub_request(:post, "https://graph.facebook.com/v21.0/123456/messages")
      .to_return(status: 200, body: '{"messages":[{"id":"wamid.ok"}]}')
  end

  def test_send_template
    result = @client.send_template(
      to: "+628123456789",
      template_name: "hello_world",
      language: "en",
      components: []
    )
    assert_equal "wamid.ok", result.dig("messages", 0, "id")
  end

  def test_send_document
    result = @client.send_document(
      to: "+628123456789",
      url: "https://example.com/doc.pdf",
      filename: "invoice.pdf",
      caption: "Your invoice"
    )
    assert_equal "wamid.ok", result.dig("messages", 0, "id")
  end

  def test_send_location
    result = @client.send_location(
      to: "+628123456789",
      latitude: -6.2,
      longitude: 106.8,
      name: "Jakarta",
      address: "Indonesia"
    )
    assert_equal "wamid.ok", result.dig("messages", 0, "id")
  end

  def test_send_contact
    result = @client.send_contact(
      to: "+628123456789",
      name: "John Doe",
      phone: "+628111111111"
    )
    assert_equal "wamid.ok", result.dig("messages", 0, "id")
  end

  def test_send_reaction
    result = @client.send_reaction(
      to: "+628123456789",
      message_id: "wamid.abc",
      emoji: "👍"
    )
    assert_equal "wamid.ok", result.dig("messages", 0, "id")
  end

  def test_send_list
    result = @client.send_list(
      to: "+628123456789",
      body: "Choose a product:",
      button_text: "View Products",
      sections: [{
        title: "Products",
        rows: [
          { id: "p1", title: "Product 1" },
          { id: "p2", title: "Product 2" }
        ]
      }]
    )
    assert_equal "wamid.ok", result.dig("messages", 0, "id")
  end

  def test_mark_as_read
    result = @client.mark_as_read(message_id: "wamid.abc")
    assert result
  end
end

# --- New Telegram message types ---

class TestTelegramNewTypes < Minitest::Test
  def setup
    ConnectorRuby.reset_configuration!
    @client = ConnectorRuby::Telegram.new(bot_token: "123:ABC")
  end

  def test_send_document
    stub_request(:post, "https://api.telegram.org/bot123:ABC/sendDocument")
      .to_return(status: 200, body: '{"ok":true,"result":{"message_id":10}}')

    result = @client.send_document(chat_id: 12345, url: "https://example.com/doc.pdf", caption: "Invoice")
    assert result["ok"]
  end

  def test_send_location
    stub_request(:post, "https://api.telegram.org/bot123:ABC/sendLocation")
      .to_return(status: 200, body: '{"ok":true,"result":{"message_id":11}}')

    result = @client.send_location(chat_id: 12345, latitude: -6.2, longitude: 106.8)
    assert result["ok"]
  end

  def test_send_typing
    stub_request(:post, "https://api.telegram.org/bot123:ABC/sendChatAction")
      .with { |req| JSON.parse(req.body)["action"] == "typing" }
      .to_return(status: 200, body: '{"ok":true}')

    result = @client.send_typing(chat_id: 12345)
    assert result["ok"]
  end
end

# --- Message builder DSL ---

class TestMessageBuilder < Minitest::Test
  def test_build_text_message
    msg = ConnectorRuby::Message.build
      .to("+628123456789")
      .text("Hello!")
      .build

    assert_equal :text, msg.type
    assert_equal "+628123456789", msg.to
    assert_equal "Hello!", msg.text
  end

  def test_build_image_message
    msg = ConnectorRuby::Message.build
      .to("user123")
      .image("https://example.com/img.jpg", caption: "A photo")
      .build

    assert_equal :image, msg.type
    assert_equal "https://example.com/img.jpg", msg.image_url
    assert_equal "A photo", msg.caption
  end

  def test_build_location_message
    msg = ConnectorRuby::Message.build
      .to("user123")
      .location(-6.2, 106.8, name: "Jakarta")
      .build

    assert_equal :location, msg.type
    assert_equal(-6.2, msg.latitude)
    assert_equal 106.8, msg.longitude
  end

  def test_build_document_message
    msg = ConnectorRuby::Message.build
      .to("user123")
      .document("https://example.com/doc.pdf", filename: "invoice.pdf")
      .build

    assert_equal :document, msg.type
    assert_equal "https://example.com/doc.pdf", msg.document_url
  end

  def test_build_requires_recipient
    assert_raises(ConnectorRuby::Error) do
      ConnectorRuby::Message.build.text("Hello!").build
    end
  end

  def test_build_requires_type
    assert_raises(ConnectorRuby::Error) do
      ConnectorRuby::Message.build.to("user123").build
    end
  end

  def test_factory_document
    msg = ConnectorRuby::Message.document(to: "123", url: "https://x.com/d.pdf", filename: "d.pdf")
    assert_equal :document, msg.type
    assert_equal "d.pdf", msg.filename
  end

  def test_factory_location
    msg = ConnectorRuby::Message.location(to: "123", latitude: 1.0, longitude: 2.0, name: "Spot")
    assert_equal :location, msg.type
    assert_equal "Spot", msg.location_name
  end

  def test_factory_contact
    msg = ConnectorRuby::Message.contact(to: "123", name: "John", phone: "+1234")
    assert_equal :contact, msg.type
    assert_equal "John", msg.contact_name
    assert_equal "+1234", msg.phone
  end
end

# --- Delivery Tracker ---

class TestDeliveryTracker < Minitest::Test
  def setup
    @tracker = ConnectorRuby::DeliveryTracker.new
  end

  def test_track_and_status
    @tracker.track("wamid.123")
    assert_equal :sent, @tracker.status("wamid.123")
  end

  def test_update_status
    @tracker.track("wamid.123")
    @tracker.update("wamid.123", status: :delivered)
    assert_equal :delivered, @tracker.status("wamid.123")
  end

  def test_status_history
    @tracker.track("wamid.123")
    @tracker.update("wamid.123", status: :delivered)
    @tracker.update("wamid.123", status: :read)

    entry = @tracker.entries["wamid.123"]
    assert_equal 3, entry[:history].size
    assert_equal :sent, entry[:history][0][:status]
    assert_equal :delivered, entry[:history][1][:status]
    assert_equal :read, entry[:history][2][:status]
  end

  def test_pending_and_delivered
    @tracker.track("msg1")
    @tracker.track("msg2")
    @tracker.update("msg2", status: :delivered)

    assert_equal 1, @tracker.pending.size
    assert_equal 1, @tracker.delivered.size
  end

  def test_callbacks
    events = []
    @tracker.on(:delivered) { |id, _| events << id }

    @tracker.track("msg1")
    @tracker.update("msg1", status: :delivered)

    assert_equal ["msg1"], events
  end

  def test_unknown_message_returns_nil
    assert_nil @tracker.update("nonexistent", status: :delivered)
    assert_nil @tracker.status("nonexistent")
  end
end

# --- Batch Sender ---

class TestBatchSender < Minitest::Test
  def test_send_batch
    channel = ConnectorRuby::Telegram.new(bot_token: "123:ABC")
    batch = ConnectorRuby::BatchSender.new(channel: channel)

    stub_request(:post, "https://api.telegram.org/bot123:ABC/sendMessage")
      .to_return(status: 200, body: '{"ok":true}')

    messages = [
      { chat_id: 1, text: "Hello 1" },
      { chat_id: 2, text: "Hello 2" }
    ]

    result = batch.send_batch(messages) do |msg|
      channel.send_text(chat_id: msg[:chat_id], text: msg[:text])
    end

    assert_equal 2, result[:total]
    assert_equal 2, result[:sent].size
    assert_equal 0, result[:failed].size
  end

  def test_send_batch_with_errors
    channel = ConnectorRuby::Telegram.new(bot_token: "123:ABC")
    batch = ConnectorRuby::BatchSender.new(channel: channel)

    call_count = 0
    stub_request(:post, "https://api.telegram.org/bot123:ABC/sendMessage")
      .to_return do
        call_count += 1
        if call_count == 2
          { status: 500, body: '{"error":"fail"}' }
        else
          { status: 200, body: '{"ok":true}' }
        end
      end

    messages = [{ chat_id: 1, text: "ok" }, { chat_id: 2, text: "fail" }, { chat_id: 3, text: "ok" }]

    result = batch.send_batch(messages) do |msg|
      channel.send_text(chat_id: msg[:chat_id], text: msg[:text])
    end

    assert_equal 3, result[:total]
    assert_equal 2, result[:sent].size
    assert_equal 1, result[:failed].size
  end
end

# --- Cross-channel event normalization ---

class TestCrossChannelNormalization < Minitest::Test
  def test_whatsapp_message_has_standard_fields
    payload = {
      "entry" => [{ "changes" => [{ "value" => {
        "messages" => [{ "from" => "628123456789", "id" => "wamid.1",
                         "timestamp" => "1700000000", "type" => "text",
                         "text" => { "body" => "Hello" } }],
        "contacts" => [{ "profile" => { "name" => "John" } }]
      } }] }]
    }
    event = ConnectorRuby::WhatsApp.parse_webhook(payload)
    assert_standard_event(event, channel: :whatsapp)
  end

  def test_telegram_message_has_standard_fields
    payload = {
      "message" => {
        "message_id" => 123,
        "from" => { "id" => 456, "username" => "johnd", "first_name" => "John" },
        "chat" => { "id" => 789, "type" => "private" },
        "date" => 1700000000,
        "text" => "Hello"
      }
    }
    event = ConnectorRuby::Telegram.parse_webhook(payload)
    assert_standard_event(event, channel: :telegram)
  end

  def test_messenger_message_has_standard_fields
    payload = {
      "entry" => [{ "messaging" => [{
        "sender" => { "id" => "user123" },
        "recipient" => { "id" => "page456" },
        "timestamp" => 1700000000000,
        "message" => { "mid" => "mid.abc", "text" => "Hello" }
      }] }]
    }
    event = ConnectorRuby::Messenger.parse_webhook(payload)
    assert_standard_event(event, channel: :messenger)
  end

  def test_line_message_has_standard_fields
    payload = {
      "events" => [{
        "type" => "message",
        "source" => { "userId" => "U123", "type" => "user" },
        "timestamp" => 1700000000000,
        "replyToken" => "reply",
        "message" => { "id" => "msg123", "type" => "text", "text" => "Hello" }
      }]
    }
    event = ConnectorRuby::Line.parse_webhook(payload)
    assert_standard_event(event, channel: :line)
  end

  def test_slack_message_has_standard_fields
    payload = {
      "event" => {
        "type" => "message",
        "user" => "U123",
        "text" => "Hello",
        "ts" => "1700000000.000000",
        "channel" => "C456"
      }
    }
    event = ConnectorRuby::Slack.parse_webhook(payload)
    assert_standard_event(event, channel: :slack)
  end

  def test_all_channels_produce_same_event_type
    events = all_channel_message_events
    events.each do |event|
      assert event.message?, "#{event.channel} should be a message event"
      assert_equal "Hello", event.text
      assert event.from, "#{event.channel} should have a from field"
      assert event.timestamp, "#{event.channel} should have a timestamp"
    end
  end

  private

  def assert_standard_event(event, channel:)
    assert_instance_of ConnectorRuby::Event, event
    assert event.message?
    assert_equal channel, event.channel
    assert event.from
    assert_equal "Hello", event.text
    assert event.timestamp
    assert event.metadata.is_a?(Hash)
  end

  def all_channel_message_events
    [
      ConnectorRuby::WhatsApp.parse_webhook({
        "entry" => [{ "changes" => [{ "value" => {
          "messages" => [{ "from" => "123", "id" => "w1", "timestamp" => "1700000000",
                           "type" => "text", "text" => { "body" => "Hello" } }],
          "contacts" => [{ "profile" => { "name" => "J" } }]
        } }] }]
      }),
      ConnectorRuby::Telegram.parse_webhook({
        "message" => { "message_id" => 1, "from" => { "id" => 123 },
                       "chat" => { "id" => 1 }, "date" => 1700000000, "text" => "Hello" }
      }),
      ConnectorRuby::Messenger.parse_webhook({
        "entry" => [{ "messaging" => [{
          "sender" => { "id" => "123" }, "recipient" => { "id" => "456" },
          "timestamp" => 1700000000000,
          "message" => { "mid" => "m1", "text" => "Hello" }
        }] }]
      }),
      ConnectorRuby::Line.parse_webhook({
        "events" => [{ "type" => "message", "source" => { "userId" => "U1", "type" => "user" },
                       "timestamp" => 1700000000000, "replyToken" => "r",
                       "message" => { "id" => "1", "type" => "text", "text" => "Hello" } }]
      }),
      ConnectorRuby::Slack.parse_webhook({
        "event" => { "type" => "message", "user" => "U1", "text" => "Hello",
                     "ts" => "1700000000.000", "channel" => "C1" }
      })
    ]
  end
end
