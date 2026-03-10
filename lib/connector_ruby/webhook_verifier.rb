# frozen_string_literal: true

require "openssl"

module ConnectorRuby
  class WebhookVerifier
    def self.verify_whatsapp(payload, signature:, app_secret:)
      expected = "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", app_secret, payload)}"
      secure_compare(expected, signature)
    end

    def self.verify_telegram(token:, payload:, secret_token: nil, header_value: nil)
      return false unless secret_token && header_value
      computed = OpenSSL::HMAC.hexdigest("SHA256", secret_token, payload.to_s)
      secure_compare(computed, header_value.to_s)
    end

    def self.secure_compare(a, b)
      a = a.to_s.downcase
      b = b.to_s.downcase
      return false unless a.bytesize == b.bytesize

      OpenSSL.fixed_length_secure_compare(a, b)
    end
  end
end
