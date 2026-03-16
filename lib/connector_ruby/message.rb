# frozen_string_literal: true

module ConnectorRuby
  class Message
    attr_reader :type, :to, :text, :buttons, :image_url, :caption, :metadata

    TYPES = %i[text buttons image template document location contact reaction list].freeze

    attr_reader :document_url, :filename, :latitude, :longitude,
                :location_name, :address, :phone, :contact_name,
                :template_name, :language, :components,
                :emoji, :sections, :button_text

    def initialize(type:, to:, text: nil, buttons: nil, image_url: nil, caption: nil, metadata: {}, **extra)
      @type = type
      @to = to
      @text = text
      @buttons = buttons
      @image_url = image_url
      @caption = caption
      @metadata = metadata
      extra.each { |k, v| instance_variable_set(:"@#{k}", v) }
    end

    # Factory methods
    def self.text(to:, text:)
      new(type: :text, to: to, text: text)
    end

    def self.buttons(to:, body:, buttons:)
      new(type: :buttons, to: to, text: body, buttons: buttons)
    end

    def self.image(to:, url:, caption: nil)
      new(type: :image, to: to, image_url: url, caption: caption)
    end

    def self.document(to:, url:, filename: nil, caption: nil)
      new(type: :document, to: to, document_url: url, filename: filename, caption: caption)
    end

    def self.location(to:, latitude:, longitude:, name: nil, address: nil)
      new(type: :location, to: to, latitude: latitude, longitude: longitude,
          location_name: name, address: address)
    end

    def self.contact(to:, name:, phone:)
      new(type: :contact, to: to, contact_name: name, phone: phone)
    end

    # Builder DSL
    def self.build
      Builder.new
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

    class Builder
      def initialize
        @attrs = { metadata: {} }
      end

      def to(recipient)
        @attrs[:to] = recipient
        self
      end

      def text(content)
        @attrs[:type] = :text
        @attrs[:text] = content
        self
      end

      def buttons(btns)
        @attrs[:type] = :buttons
        @attrs[:buttons] = btns
        self
      end

      def image(url, caption: nil)
        @attrs[:type] = :image
        @attrs[:image_url] = url
        @attrs[:caption] = caption
        self
      end

      def document(url, filename: nil)
        @attrs[:type] = :document
        @attrs[:document_url] = url
        @attrs[:filename] = filename
        self
      end

      def location(lat, lng, name: nil)
        @attrs[:type] = :location
        @attrs[:latitude] = lat
        @attrs[:longitude] = lng
        @attrs[:location_name] = name
        self
      end

      def metadata(hash)
        @attrs[:metadata] = hash
        self
      end

      def build
        raise ConnectorRuby::Error, "Message requires a recipient" unless @attrs[:to]
        raise ConnectorRuby::Error, "Message requires a type" unless @attrs[:type]
        Message.new(**@attrs)
      end
    end
  end
end
