# connector-ruby

Unified channel messaging SDK for Ruby. Framework-agnostic SDK for sending/receiving messages across chat platforms.

## Installation

```ruby
gem "connector-ruby", "~> 0.1"
```

## Supported Channels

- WhatsApp Cloud API
- Telegram Bot API

## Usage

### WhatsApp

```ruby
client = ConnectorRuby::WhatsApp.new(
  phone_number_id: "...",
  access_token: "..."
)

client.send_text(to: "+62812...", text: "Hello!")
client.send_buttons(to: "+62812...", body: "Choose:", buttons: [
  { id: "opt1", title: "Option 1" },
  { id: "opt2", title: "Option 2" }
])
client.send_image(to: "+62812...", url: "https://...")

event = ConnectorRuby::WhatsApp.parse_webhook(request_body)
```

### Telegram

```ruby
client = ConnectorRuby::Telegram.new(bot_token: "...")

client.send_text(chat_id: 12345, text: "Hello!")
event = ConnectorRuby::Telegram.parse_webhook(request_body)
```

### Configuration

```ruby
ConnectorRuby.configure do |config|
  config.whatsapp_phone_number_id = ENV["WA_PHONE_ID"]
  config.whatsapp_access_token = ENV["WA_TOKEN"]
  config.telegram_bot_token = ENV["TG_TOKEN"]
  config.http_timeout = 30
  config.http_retries = 3
end
```

## License

MIT
