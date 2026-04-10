# frozen_string_literal: true

module ConnectorRuby
  class Configuration
    attr_accessor :whatsapp_phone_number_id, :whatsapp_access_token,
                  :telegram_bot_token,
                  :messenger_page_access_token,
                  :line_channel_access_token,
                  :slack_bot_token,
                  :livechat_pat, :livechat_region,
                  :http_timeout, :http_retries, :http_open_timeout,
                  :on_request, :on_response, :on_error

    def initialize
      @whatsapp_phone_number_id = nil
      @whatsapp_access_token = nil
      @telegram_bot_token = nil
      @messenger_page_access_token = nil
      @line_channel_access_token = nil
      @slack_bot_token = nil
      @livechat_pat = nil
      @livechat_region = nil
      @http_timeout = 30
      @http_retries = 3
      @http_open_timeout = 10
      @on_request = nil
      @on_response = nil
      @on_error = nil
    end
  end
end
