# frozen_string_literal: true

module ConnectorRuby
  module Channels
    class Base
      def send_text(*)
        raise NotImplementedError, "#{self.class}#send_text not implemented"
      end

      def send_buttons(*)
        raise NotImplementedError, "#{self.class}#send_buttons not implemented"
      end

      def send_image(*)
        raise NotImplementedError, "#{self.class}#send_image not implemented"
      end

      def self.parse_webhook(*)
        raise NotImplementedError, "#{self}.parse_webhook not implemented"
      end

      private

      def http_client
        @http_client ||= HttpClient.new
      end
    end
  end
end
