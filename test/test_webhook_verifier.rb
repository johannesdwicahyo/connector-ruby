# frozen_string_literal: true

require_relative "test_helper"

class TestWebhookVerifier < Minitest::Test
  # ---- WhatsApp --------------------------------------------------------

  def test_whatsapp_verification_valid
    payload = '{"test":"data"}'
    secret = "my_app_secret"
    signature = "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, payload)}"

    assert ConnectorRuby::WebhookVerifier.verify_whatsapp(
      payload, signature: signature, app_secret: secret
    )
  end

  def test_whatsapp_verification_invalid
    refute ConnectorRuby::WebhookVerifier.verify_whatsapp(
      '{"test":"data"}',
      signature: "sha256=invalid0000000000000000000000000000000000000000000000000000000000",
      app_secret: "secret"
    )
  end

  # ---- Telegram --------------------------------------------------------

  def test_telegram_verification_valid
    secret = "my_secret_token"
    payload = '{"update_id":123}'
    header_value = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)

    assert ConnectorRuby::WebhookVerifier.verify_telegram(
      token: "123:ABC",
      payload: payload,
      secret_token: secret,
      header_value: header_value
    )
  end

  def test_telegram_verification_invalid
    secret = "my_secret_token"
    payload = '{"update_id":123}'

    refute ConnectorRuby::WebhookVerifier.verify_telegram(
      token: "123:ABC",
      payload: payload,
      secret_token: secret,
      header_value: "0" * 64
    )
  end

  def test_telegram_verification_missing_secret
    refute ConnectorRuby::WebhookVerifier.verify_telegram(
      token: "123:ABC",
      payload: '{"update_id":123}',
      secret_token: nil,
      header_value: "something"
    )
  end

  # ---- Messenger -------------------------------------------------------

  def test_messenger_verification_valid
    payload = '{"object":"page","entry":[]}'
    secret = "messenger_app_secret"
    signature = "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, payload)}"

    assert ConnectorRuby::WebhookVerifier.verify_messenger(
      payload, signature: signature, app_secret: secret
    )
  end

  def test_messenger_verification_wrong_secret
    payload = '{"object":"page","entry":[]}'
    signature = "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", "wrong_secret", payload)}"

    refute ConnectorRuby::WebhookVerifier.verify_messenger(
      payload, signature: signature, app_secret: "right_secret"
    )
  end

  def test_messenger_verification_tampered_payload
    secret = "messenger_app_secret"
    signature = "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, '{"original":"data"}')}"

    refute ConnectorRuby::WebhookVerifier.verify_messenger(
      '{"tampered":"data"}', signature: signature, app_secret: secret
    )
  end

  def test_messenger_verification_nil_signature
    refute ConnectorRuby::WebhookVerifier.verify_messenger(
      '{"test":"data"}', signature: nil, app_secret: "secret"
    )
  end

  def test_messenger_verification_nil_secret
    refute ConnectorRuby::WebhookVerifier.verify_messenger(
      '{"test":"data"}', signature: "sha256=abc", app_secret: nil
    )
  end

  # ---- LINE ------------------------------------------------------------

  def test_line_verification_valid
    payload = '{"events":[{"type":"message","message":{"text":"hi"}}]}'
    secret = "line_channel_secret"
    digest = OpenSSL::HMAC.digest("SHA256", secret, payload)
    signature = Base64.strict_encode64(digest)

    assert ConnectorRuby::WebhookVerifier.verify_line(
      payload, signature: signature, channel_secret: secret
    )
  end

  def test_line_verification_wrong_secret
    payload = '{"events":[]}'
    digest = OpenSSL::HMAC.digest("SHA256", "wrong_secret", payload)
    signature = Base64.strict_encode64(digest)

    refute ConnectorRuby::WebhookVerifier.verify_line(
      payload, signature: signature, channel_secret: "right_secret"
    )
  end

  def test_line_verification_tampered_payload
    secret = "line_channel_secret"
    digest = OpenSSL::HMAC.digest("SHA256", secret, '{"original":"data"}')
    signature = Base64.strict_encode64(digest)

    refute ConnectorRuby::WebhookVerifier.verify_line(
      '{"tampered":"data"}', signature: signature, channel_secret: secret
    )
  end

  def test_line_verification_is_case_sensitive
    # Base64 signatures are case-sensitive — downcasing must not verify
    # when the original contained uppercase characters.
    payload = '{"events":[]}'
    secret = "line_channel_secret"
    digest = OpenSSL::HMAC.digest("SHA256", secret, payload)
    signature = Base64.strict_encode64(digest)

    skip "signature happens to contain no uppercase characters" if signature == signature.downcase

    refute ConnectorRuby::WebhookVerifier.verify_line(
      payload, signature: signature.downcase, channel_secret: secret
    )
  end

  def test_line_verification_nil_signature
    refute ConnectorRuby::WebhookVerifier.verify_line(
      '{"events":[]}', signature: nil, channel_secret: "secret"
    )
  end

  def test_line_verification_nil_channel_secret
    refute ConnectorRuby::WebhookVerifier.verify_line(
      '{"events":[]}', signature: "abc", channel_secret: nil
    )
  end

  # ---- Slack -----------------------------------------------------------

  def test_slack_verification_valid
    secret = "slack_signing_secret"
    payload = '{"token":"xxx","type":"event_callback"}'
    timestamp = Time.now.to_i.to_s
    basestring = "v0:#{timestamp}:#{payload}"
    signature = "v0=#{OpenSSL::HMAC.hexdigest("SHA256", secret, basestring)}"

    assert ConnectorRuby::WebhookVerifier.verify_slack(
      payload, timestamp: timestamp, signature: signature, signing_secret: secret
    )
  end

  def test_slack_verification_wrong_secret
    payload = '{"token":"xxx"}'
    timestamp = Time.now.to_i.to_s
    basestring = "v0:#{timestamp}:#{payload}"
    signature = "v0=#{OpenSSL::HMAC.hexdigest("SHA256", "wrong_secret", basestring)}"

    refute ConnectorRuby::WebhookVerifier.verify_slack(
      payload, timestamp: timestamp, signature: signature, signing_secret: "right_secret"
    )
  end

  def test_slack_verification_tampered_payload
    secret = "slack_signing_secret"
    timestamp = Time.now.to_i.to_s
    basestring = "v0:#{timestamp}:#{'{"original":"data"}'}"
    signature = "v0=#{OpenSSL::HMAC.hexdigest("SHA256", secret, basestring)}"

    refute ConnectorRuby::WebhookVerifier.verify_slack(
      '{"tampered":"data"}',
      timestamp: timestamp, signature: signature, signing_secret: secret
    )
  end

  def test_slack_verification_rejects_stale_timestamp
    secret = "slack_signing_secret"
    payload = '{"token":"xxx"}'
    timestamp = (Time.now.to_i - 600).to_s # 10 min ago; outside default 5-min tolerance
    basestring = "v0:#{timestamp}:#{payload}"
    signature = "v0=#{OpenSSL::HMAC.hexdigest("SHA256", secret, basestring)}"

    refute ConnectorRuby::WebhookVerifier.verify_slack(
      payload, timestamp: timestamp, signature: signature, signing_secret: secret
    )
  end

  def test_slack_verification_rejects_future_timestamp
    secret = "slack_signing_secret"
    payload = '{"token":"xxx"}'
    timestamp = (Time.now.to_i + 600).to_s
    basestring = "v0:#{timestamp}:#{payload}"
    signature = "v0=#{OpenSSL::HMAC.hexdigest("SHA256", secret, basestring)}"

    refute ConnectorRuby::WebhookVerifier.verify_slack(
      payload, timestamp: timestamp, signature: signature, signing_secret: secret
    )
  end

  def test_slack_verification_custom_tolerance
    secret = "slack_signing_secret"
    payload = '{"token":"xxx"}'
    timestamp = (Time.now.to_i - 1000).to_s # 16+ minutes ago
    basestring = "v0:#{timestamp}:#{payload}"
    signature = "v0=#{OpenSSL::HMAC.hexdigest("SHA256", secret, basestring)}"

    # Default 5-min tolerance → rejected
    refute ConnectorRuby::WebhookVerifier.verify_slack(
      payload, timestamp: timestamp, signature: signature, signing_secret: secret
    )

    # Extended tolerance → accepted
    assert ConnectorRuby::WebhookVerifier.verify_slack(
      payload, timestamp: timestamp, signature: signature, signing_secret: secret, tolerance: 2000
    )
  end

  def test_slack_verification_missing_timestamp
    refute ConnectorRuby::WebhookVerifier.verify_slack(
      '{"token":"xxx"}', timestamp: nil, signature: "v0=abc", signing_secret: "secret"
    )
  end

  def test_slack_verification_non_numeric_timestamp
    refute ConnectorRuby::WebhookVerifier.verify_slack(
      '{"token":"xxx"}', timestamp: "not_a_number", signature: "v0=abc", signing_secret: "secret"
    )
  end

  def test_slack_verification_missing_signature
    refute ConnectorRuby::WebhookVerifier.verify_slack(
      '{"token":"xxx"}', timestamp: Time.now.to_i.to_s, signature: nil, signing_secret: "secret"
    )
  end

  def test_slack_verification_missing_signing_secret
    refute ConnectorRuby::WebhookVerifier.verify_slack(
      '{"token":"xxx"}', timestamp: Time.now.to_i.to_s, signature: "v0=abc", signing_secret: nil
    )
  end

  # ---- LiveChat --------------------------------------------------------

  def test_livechat_verification_valid_string_body
    secret = "livechat_shared_secret_xyz"
    body = JSON.generate(
      "action" => "incoming_event",
      "secret_key" => secret,
      "payload" => {}
    )

    assert ConnectorRuby::WebhookVerifier.verify_livechat(body, expected_secret: secret)
  end

  def test_livechat_verification_valid_hash_body
    secret = "livechat_shared_secret_xyz"
    body = { "action" => "incoming_event", "secret_key" => secret, "payload" => {} }

    assert ConnectorRuby::WebhookVerifier.verify_livechat(body, expected_secret: secret)
  end

  def test_livechat_verification_wrong_secret
    body = JSON.generate(
      "action" => "incoming_event",
      "secret_key" => "wrong_secret",
      "payload" => {}
    )

    refute ConnectorRuby::WebhookVerifier.verify_livechat(body, expected_secret: "right_secret")
  end

  def test_livechat_verification_missing_secret_key_field
    body = JSON.generate("action" => "incoming_event", "payload" => {})

    refute ConnectorRuby::WebhookVerifier.verify_livechat(body, expected_secret: "secret")
  end

  def test_livechat_verification_nil_expected_secret
    body = JSON.generate("secret_key" => "anything")

    refute ConnectorRuby::WebhookVerifier.verify_livechat(body, expected_secret: nil)
  end

  def test_livechat_verification_malformed_json
    refute ConnectorRuby::WebhookVerifier.verify_livechat("not valid json", expected_secret: "secret")
  end

  def test_livechat_verification_non_hash_parsed_body
    refute ConnectorRuby::WebhookVerifier.verify_livechat("[1,2,3]", expected_secret: "secret")
  end

  def test_livechat_verification_is_case_sensitive
    secret = "CaseSensitiveSecret"
    body = JSON.generate("secret_key" => secret.downcase)

    refute ConnectorRuby::WebhookVerifier.verify_livechat(body, expected_secret: secret)
  end
end
