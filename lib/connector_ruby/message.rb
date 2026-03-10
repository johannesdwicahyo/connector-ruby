# frozen_string_literal: true

module ConnectorRuby
  class Message
    attr_reader :type, :to, :text, :buttons, :image_url, :caption, :metadata

    TYPES = %i[text buttons image template].freeze

    def initialize(type:, to:, text: nil, buttons: nil, image_url: nil, caption: nil, metadata: {})
      @type = type
      @to = to
      @text = text
      @buttons = buttons
      @image_url = image_url
      @caption = caption
      @metadata = metadata
    end

    def self.text(to:, text:)
      new(type: :text, to: to, text: text)
    end

    def self.buttons(to:, body:, buttons:)
      new(type: :buttons, to: to, text: body, buttons: buttons)
    end

    def self.image(to:, url:, caption: nil)
      new(type: :image, to: to, image_url: url, caption: caption)
    end

    def to_h
      {
        type: @type,
        to: @to,
        text: @text,
        buttons: @buttons,
        image_url: @image_url,
        caption: @caption,
        metadata: @metadata
      }.compact
    end
  end
end
