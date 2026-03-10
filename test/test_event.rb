# frozen_string_literal: true

require_relative "test_helper"

class TestEvent < Minitest::Test
  def test_message_event
    event = ConnectorRuby::Event.new(
      type: :message,
      channel: :whatsapp,
      from: "+628123456789",
      text: "Hello!"
    )

    assert event.message?
    refute event.callback?
    refute event.status?
    assert_equal :whatsapp, event.channel
    assert_equal "+628123456789", event.from
    assert_equal "Hello!", event.text
  end

  def test_callback_event
    event = ConnectorRuby::Event.new(
      type: :callback,
      channel: :telegram,
      from: "12345",
      text: "opt1"
    )

    refute event.message?
    assert event.callback?
    assert_equal :telegram, event.channel
  end

  def test_to_h
    event = ConnectorRuby::Event.new(
      type: :message,
      channel: :whatsapp,
      from: "+628123456789",
      text: "Hello!"
    )

    hash = event.to_h
    assert_equal :message, hash[:type]
    assert_equal :whatsapp, hash[:channel]
    assert_equal "+628123456789", hash[:from]
    assert_equal "Hello!", hash[:text]
  end
end
