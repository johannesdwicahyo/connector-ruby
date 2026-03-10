# connector-ruby

Unified channel messaging SDK for Ruby. Send and receive messages across WhatsApp and Telegram with a consistent API.

## Installation

```ruby
gem "connector-ruby"
```

## Usage

```ruby
require "connector_ruby"

# WhatsApp
wa = ConnectorRuby::Channels::WhatsApp.new(
  access_token: ENV["WHATSAPP_TOKEN"],
  phone_number_id: ENV["WHATSAPP_PHONE_ID"]
)
wa.send_text(to: "+1234567890", text: "Hello!")

# Telegram
tg = ConnectorRuby::Channels::Telegram.new(bot_token: ENV["TELEGRAM_TOKEN"])
tg.send_text(to: "chat_id", text: "Hello!")

# Webhook verification
verifier = ConnectorRuby::WebhookVerifier.new(secret_token: "secret")
verifier.verify!(request_body, signature_header)
```

## Features

- WhatsApp Business API (text, buttons, images)
- Telegram Bot API (text, callbacks)
- HMAC-SHA256 webhook verification
- HTTP retry with exponential backoff for 429/5xx
- Input validation and error handling
- Logging hooks (on_request, on_response, on_error)

## License

MIT
