# frozen_string_literal: true

require_relative "test_helper"

class TestWebhookVerifier < Minitest::Test
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
      '{"test":"data"}', signature: "sha256=invalid0000000000000000000000000000000000000000000000000000000000", app_secret: "secret"
    )
  end

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
end
