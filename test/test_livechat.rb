# frozen_string_literal: true

require_relative "test_helper"

class TestLiveChat < Minitest::Test
  SEND_EVENT_URL = "https://api.livechatinc.com/v3.5/agent/action/send_event"

  def setup
    ConnectorRuby.reset_configuration!
    WebMock.reset!
    WebMock.disable_net_connect!
  end

  def teardown
    ConnectorRuby.reset_configuration!
  end

  # ---- initialize ------------------------------------------------------

  def test_initialize_raises_without_pat
    assert_raises(ConnectorRuby::ConfigurationError) do
      ConnectorRuby::Channels::LiveChat.new
    end
  end

  def test_initialize_reads_from_configuration
    ConnectorRuby.configure do |c|
      c.livechat_pat = "configured_pat"
      c.livechat_region = "dal"
    end

    # No raise = success
    ConnectorRuby::Channels::LiveChat.new
  end

  def test_initialize_accepts_explicit_pat
    ConnectorRuby::Channels::LiveChat.new(pat: "explicit_pat")
  end

  def test_initialize_explicit_pat_overrides_configuration
    ConnectorRuby.configure { |c| c.livechat_pat = "from_config" }
    client = ConnectorRuby::Channels::LiveChat.new(pat: "from_arg")

    stub_request(:post, SEND_EVENT_URL)
      .with(headers: { "Authorization" => "Basic from_arg" })
      .to_return(status: 200, body: '{"event_id":"evt_1"}', headers: { "Content-Type" => "application/json" })

    client.send_text(to: "CHAT_abc", text: "Hello")
  end

  # ---- send_text -------------------------------------------------------

  def test_send_text_posts_correct_body
    stub = stub_request(:post, SEND_EVENT_URL)
      .with(
        body: JSON.generate(
          chat_id: "CHAT_abc",
          event: { type: "message", text: "Hello" }
        ),
        headers: { "Authorization" => "Basic my_pat" }
      )
      .to_return(status: 200, body: '{"event_id":"evt_1"}', headers: { "Content-Type" => "application/json" })

    client = ConnectorRuby::Channels::LiveChat.new(pat: "my_pat")
    client.send_text(to: "CHAT_abc", text: "Hello")

    assert_requested(stub)
  end

  def test_send_text_includes_x_region_header_when_configured
    stub = stub_request(:post, SEND_EVENT_URL)
      .with(
        headers: {
          "Authorization" => "Basic my_pat",
          "X-Region" => "dal"
        }
      )
      .to_return(status: 200, body: '{"event_id":"evt_1"}', headers: { "Content-Type" => "application/json" })

    client = ConnectorRuby::Channels::LiveChat.new(pat: "my_pat", region: "dal")
    client.send_text(to: "CHAT_abc", text: "Hello")

    assert_requested(stub)
  end

  def test_send_text_omits_x_region_header_when_not_configured
    stub_request(:post, SEND_EVENT_URL)
      .to_return(status: 200, body: '{"event_id":"evt_1"}', headers: { "Content-Type" => "application/json" })

    client = ConnectorRuby::Channels::LiveChat.new(pat: "my_pat")
    client.send_text(to: "CHAT_abc", text: "Hello")

    assert_requested(:post, SEND_EVENT_URL) do |req|
      !req.headers.key?("X-Region")
    end
  end

  def test_send_text_raises_on_nil_recipient
    client = ConnectorRuby::Channels::LiveChat.new(pat: "my_pat")
    assert_raises(ConnectorRuby::Error) do
      client.send_text(to: nil, text: "Hello")
    end
  end

  def test_send_text_raises_on_empty_recipient
    client = ConnectorRuby::Channels::LiveChat.new(pat: "my_pat")
    assert_raises(ConnectorRuby::Error) do
      client.send_text(to: "   ", text: "Hello")
    end
  end

  def test_send_text_raises_on_nil_text
    client = ConnectorRuby::Channels::LiveChat.new(pat: "my_pat")
    assert_raises(ConnectorRuby::Error) do
      client.send_text(to: "CHAT_abc", text: nil)
    end
  end

  def test_send_text_raises_on_empty_text
    client = ConnectorRuby::Channels::LiveChat.new(pat: "my_pat")
    assert_raises(ConnectorRuby::Error) do
      client.send_text(to: "CHAT_abc", text: "")
    end
  end

  # ---- parse_webhook ---------------------------------------------------

  def test_parse_webhook_returns_event_for_incoming_message_from_string
    body = JSON.generate(
      "action" => "incoming_event",
      "organization_id" => "org_xyz",
      "payload" => {
        "chat_id" => "CHAT_abc",
        "thread_id" => "THREAD_xyz",
        "event" => {
          "id" => "evt_001",
          "type" => "message",
          "text" => "I need help",
          "author_id" => "customer_456",
          "created_at" => "2026-04-11T00:00:00.000Z"
        }
      }
    )

    event = ConnectorRuby::Channels::LiveChat.parse_webhook(body)

    refute_nil event
    assert_equal :message, event.type
    assert_equal :livechat, event.channel
    assert_equal "customer_456", event.from
    assert_equal "I need help", event.text
    assert_equal "evt_001", event.message_id
    assert_equal "CHAT_abc", event.metadata[:chat_id]
    assert_equal "THREAD_xyz", event.metadata[:thread_id]
    assert_equal "org_xyz", event.metadata[:organization_id]
    refute_nil event.timestamp
  end

  def test_parse_webhook_accepts_hash_input
    body = {
      "action" => "incoming_event",
      "payload" => {
        "event" => { "type" => "message", "text" => "hi", "author_id" => "u1", "id" => "e1" }
      }
    }

    event = ConnectorRuby::Channels::LiveChat.parse_webhook(body)

    refute_nil event
    assert_equal "hi", event.text
    assert_equal "u1", event.from
  end

  def test_parse_webhook_returns_nil_for_incoming_chat
    body = JSON.generate("action" => "incoming_chat", "payload" => {})
    assert_nil ConnectorRuby::Channels::LiveChat.parse_webhook(body)
  end

  def test_parse_webhook_returns_nil_for_chat_deactivated
    body = JSON.generate("action" => "chat_deactivated", "payload" => {})
    assert_nil ConnectorRuby::Channels::LiveChat.parse_webhook(body)
  end

  def test_parse_webhook_returns_nil_for_non_message_event_type
    body = JSON.generate(
      "action" => "incoming_event",
      "payload" => { "event" => { "type" => "file", "url" => "https://x.com/y.jpg" } }
    )
    assert_nil ConnectorRuby::Channels::LiveChat.parse_webhook(body)
  end

  def test_parse_webhook_returns_nil_for_system_message
    body = JSON.generate(
      "action" => "incoming_event",
      "payload" => { "event" => { "type" => "system_message" } }
    )
    assert_nil ConnectorRuby::Channels::LiveChat.parse_webhook(body)
  end

  def test_parse_webhook_returns_nil_for_malformed_json
    assert_nil ConnectorRuby::Channels::LiveChat.parse_webhook("not json")
  end

  def test_parse_webhook_returns_nil_for_missing_payload
    body = JSON.generate("action" => "incoming_event")
    assert_nil ConnectorRuby::Channels::LiveChat.parse_webhook(body)
  end

  def test_parse_webhook_returns_nil_for_missing_event
    body = JSON.generate("action" => "incoming_event", "payload" => { "chat_id" => "X" })
    assert_nil ConnectorRuby::Channels::LiveChat.parse_webhook(body)
  end

  def test_parse_webhook_handles_invalid_timestamp_gracefully
    body = JSON.generate(
      "action" => "incoming_event",
      "payload" => {
        "event" => {
          "id" => "e1", "type" => "message", "text" => "hi",
          "author_id" => "u1", "created_at" => "not a real date"
        }
      }
    )

    event = ConnectorRuby::Channels::LiveChat.parse_webhook(body)
    refute_nil event
    assert_nil event.timestamp
  end
end
