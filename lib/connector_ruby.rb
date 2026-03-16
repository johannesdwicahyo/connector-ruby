# frozen_string_literal: true

require_relative "connector_ruby/version"
require_relative "connector_ruby/error"
require_relative "connector_ruby/configuration"
require_relative "connector_ruby/event"
require_relative "connector_ruby/message"
require_relative "connector_ruby/http_client"
require_relative "connector_ruby/webhook_verifier"
require_relative "connector_ruby/channels/base"
require_relative "connector_ruby/channels/whatsapp"
require_relative "connector_ruby/channels/telegram"
require_relative "connector_ruby/channels/messenger"
require_relative "connector_ruby/channels/line"
require_relative "connector_ruby/channels/slack"
require_relative "connector_ruby/batch_sender"
require_relative "connector_ruby/delivery_tracker"

module ConnectorRuby
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end

  # Convenience aliases
  WhatsApp = Channels::WhatsApp
  Telegram = Channels::Telegram
  Messenger = Channels::Messenger
  Line = Channels::Line
  Slack = Channels::Slack
end
