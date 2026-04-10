# frozen_string_literal: true

require "openssl"
require "base64"
require "json"

module ConnectorRuby
  class WebhookVerifier
    # Verify a WhatsApp Cloud API webhook signature.
    #
    # WhatsApp sends the signature in the `X-Hub-Signature-256` header as
    # `sha256=<hex>`, computed with HMAC-SHA256 over the raw request body
    # using the app secret as the key.
    def self.verify_whatsapp(payload, signature:, app_secret:)
      expected = "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", app_secret, payload)}"
      secure_compare(expected, signature)
    end

    # Verify a Telegram webhook using the `X-Telegram-Bot-Api-Secret-Token`
    # header configured via `setWebhook`.
    def self.verify_telegram(token:, payload:, secret_token: nil, header_value: nil)
      return false unless secret_token && header_value
      computed = OpenSSL::HMAC.hexdigest("SHA256", secret_token, payload.to_s)
      secure_compare(computed, header_value.to_s)
    end

    # Verify a Meta Messenger webhook signature.
    #
    # Messenger sends the signature in the `X-Hub-Signature-256` header as
    # `sha256=<hex>`, computed with HMAC-SHA256 over the raw request body
    # using the Facebook app secret as the key.
    #
    # Reference: https://developers.facebook.com/docs/messenger-platform/webhooks#security
    def self.verify_messenger(payload, signature:, app_secret:)
      return false if signature.nil? || app_secret.nil?
      expected = "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", app_secret, payload.to_s)}"
      secure_compare(expected, signature)
    end

    # Verify a LINE Messaging API webhook signature.
    #
    # LINE sends the signature in the `X-Line-Signature` header as the
    # Base64-encoded HMAC-SHA256 digest of the raw request body, using the
    # channel secret as the key.
    #
    # Because the signature is Base64 (which contains uppercase letters),
    # the comparison is case-sensitive.
    #
    # Reference: https://developers.line.biz/en/reference/messaging-api/#signature-validation
    def self.verify_line(payload, signature:, channel_secret:)
      return false if signature.nil? || channel_secret.nil?
      digest = OpenSSL::HMAC.digest("SHA256", channel_secret, payload.to_s)
      expected = Base64.strict_encode64(digest)
      secure_compare(expected, signature, case_sensitive: true)
    end

    # Verify a Slack webhook signature with replay protection.
    #
    # Slack sends the signature in `X-Slack-Signature` as `v0=<hex>`, computed
    # as HMAC-SHA256 over the base string `v0:{timestamp}:{body}` using the
    # signing secret as the key. The `X-Slack-Request-Timestamp` value must
    # also be checked for freshness to prevent replay attacks.
    #
    # @param tolerance [Integer] max allowed delta between the timestamp and
    #   the current time, in seconds (default 300 = 5 minutes, matching
    #   Slack's own recommendation).
    #
    # Reference: https://api.slack.com/authentication/verifying-requests-from-slack
    def self.verify_slack(payload, timestamp:, signature:, signing_secret:, tolerance: 300)
      return false if timestamp.nil? || signature.nil? || signing_secret.nil?
      ts = timestamp.to_i
      return false if ts.zero?
      return false if (Time.now.to_i - ts).abs > tolerance

      basestring = "v0:#{ts}:#{payload}"
      expected = "v0=#{OpenSSL::HMAC.hexdigest("SHA256", signing_secret, basestring)}"
      secure_compare(expected, signature)
    end

    # Verify a LiveChat webhook using the shared secret embedded in the body.
    #
    # LiveChat does NOT sign webhooks with HMAC and does NOT use a signature
    # header. Instead, every webhook body contains a `secret_key` field;
    # verification is a constant-time compare between that field and the
    # shared secret you configured in your LiveChat webhook settings.
    #
    # Reference: https://platform.text.com/docs/messaging/webhooks
    #   and (production reference) chatbotlic's webhooks_controller.rb
    def self.verify_livechat(payload, expected_secret:)
      return false if expected_secret.nil?

      data = payload.is_a?(String) ? JSON.parse(payload) : payload
      return false unless data.is_a?(Hash)

      received = data["secret_key"]
      return false if received.nil?

      secure_compare(received.to_s, expected_secret.to_s, case_sensitive: true)
    rescue JSON::ParserError
      false
    end

    # Constant-time string comparison.
    #
    # By default, comparisons are case-insensitive (safe for hex signatures).
    # Pass `case_sensitive: true` for Base64 or shared-secret comparisons where
    # case carries meaning.
    def self.secure_compare(a, b, case_sensitive: false)
      a = a.to_s
      b = b.to_s
      unless case_sensitive
        a = a.downcase
        b = b.downcase
      end
      return false unless a.bytesize == b.bytesize

      OpenSSL.fixed_length_secure_compare(a, b)
    end
  end
end
