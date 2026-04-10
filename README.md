# connector-ruby

Unified channel messaging SDK for Ruby. Send and receive messages across **WhatsApp, Telegram, Facebook Messenger, LINE, Slack, and LiveChat** with a consistent API, normalized webhook events, and first-class signature verification for every channel.

## Installation

```ruby
gem "connector-ruby", "~> 0.3"
```

```ruby
require "connector_ruby"
```

## Channel support

| Channel | Send text | Send buttons | Send image | Rich messages | Parse webhook | Verify webhook |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| WhatsApp   | ✅ | ✅ | ✅ | templates, documents, location, contacts, reactions, lists | ✅ | ✅ |
| Telegram   | ✅ | ✅ | ✅ | documents, location | ✅ | ✅ |
| Messenger  | ✅ | ✅ | ✅ | quick replies | ✅ | ✅ |
| LINE       | ✅ | ✅ | ✅ | flex messages | ✅ | ✅ |
| Slack      | ✅ | ✅ | ✅ | blocks | ✅ | ✅ |
| LiveChat   | ✅ | — | — | *(minimal in v0.3.0)* | ✅ | ✅ |

## Quickstart

```ruby
# WhatsApp Cloud API
wa = ConnectorRuby::WhatsApp.new(
  access_token: ENV["WHATSAPP_TOKEN"],
  phone_number_id: ENV["WHATSAPP_PHONE_ID"]
)
wa.send_text(to: "+6281234567890", text: "Hello!")

# Telegram Bot API
tg = ConnectorRuby::Telegram.new(bot_token: ENV["TELEGRAM_BOT_TOKEN"])
tg.send_text(to: "chat_id", text: "Hello!")

# Facebook Messenger
fb = ConnectorRuby::Messenger.new(page_access_token: ENV["MESSENGER_PAGE_TOKEN"])
fb.send_text(to: "psid", text: "Hello!")

# LINE Messaging API
line = ConnectorRuby::Line.new(channel_access_token: ENV["LINE_CHANNEL_TOKEN"])
line.send_text(to: "user_id", text: "Hello!")

# Slack Web API
slack = ConnectorRuby::Slack.new(bot_token: ENV["SLACK_BOT_TOKEN"])
slack.send_text(channel: "C0123456", text: "Hello!")

# LiveChat Agent API (Basic auth with a PAT)
lc = ConnectorRuby::LiveChat.new(
  pat: ENV["LIVECHAT_PAT"],       # base64(account_id:region:pat_value)
  region: ENV["LIVECHAT_REGION"]  # e.g. "dal" — extracted from the PAT
)
lc.send_text(to: "CHAT_abc123", text: "Hello!")
```

## Global configuration

Configure credentials once and every channel picks them up automatically:

```ruby
ConnectorRuby.configure do |c|
  c.whatsapp_phone_number_id      = ENV["WHATSAPP_PHONE_ID"]
  c.whatsapp_access_token         = ENV["WHATSAPP_TOKEN"]
  c.telegram_bot_token            = ENV["TELEGRAM_BOT_TOKEN"]
  c.messenger_page_access_token   = ENV["MESSENGER_PAGE_TOKEN"]
  c.line_channel_access_token     = ENV["LINE_CHANNEL_TOKEN"]
  c.slack_bot_token               = ENV["SLACK_BOT_TOKEN"]
  c.livechat_pat                  = ENV["LIVECHAT_PAT"]
  c.livechat_region               = ENV["LIVECHAT_REGION"]

  # HTTP client
  c.http_timeout      = 30
  c.http_retries      = 3
  c.http_open_timeout = 10

  # Instrumentation callbacks
  c.on_request  = ->(method:, url:, headers:, body:) { Rails.logger.info("[connector] → #{method} #{url}") }
  c.on_response = ->(status:, body:)                  { Rails.logger.info("[connector] ← #{status}") }
  c.on_error    = ->(error:)                          { Sentry.capture_exception(error) }
end
```

## Parsing inbound webhooks

Every channel exposes a `parse_webhook` class method that returns a normalized `ConnectorRuby::Event`:

```ruby
event = ConnectorRuby::WhatsApp.parse_webhook(request.raw_post)
# => #<ConnectorRuby::Event type=:message channel=:whatsapp from="+6281..." text="Hi">

event.message?            # => true
event.text                # => "Hi"
event.from                # => "+6281234567890"
event.channel             # => :whatsapp
event.metadata            # => channel-specific extras
```

Same shape for `Telegram`, `Messenger`, `Line`, `Slack`, `LiveChat`.

## Webhook verification

Each channel has its own verification contract. `WebhookVerifier` has a dedicated method per provider — don't hand-roll HMACs in your controllers.

```ruby
# WhatsApp — X-Hub-Signature-256: sha256=<hex>
ConnectorRuby::WebhookVerifier.verify_whatsapp(
  request.raw_post,
  signature: request.headers["X-Hub-Signature-256"],
  app_secret: ENV["WHATSAPP_APP_SECRET"]
)

# Telegram — X-Telegram-Bot-Api-Secret-Token (configured via setWebhook)
ConnectorRuby::WebhookVerifier.verify_telegram(
  token: ENV["TELEGRAM_BOT_TOKEN"],
  payload: request.raw_post,
  secret_token: ENV["TELEGRAM_WEBHOOK_SECRET"],
  header_value: request.headers["X-Telegram-Bot-Api-Secret-Token"]
)

# Messenger — X-Hub-Signature-256: sha256=<hex>
ConnectorRuby::WebhookVerifier.verify_messenger(
  request.raw_post,
  signature: request.headers["X-Hub-Signature-256"],
  app_secret: ENV["FB_APP_SECRET"]
)

# LINE — X-Line-Signature: <base64 HMAC-SHA256>
ConnectorRuby::WebhookVerifier.verify_line(
  request.raw_post,
  signature: request.headers["X-Line-Signature"],
  channel_secret: ENV["LINE_CHANNEL_SECRET"]
)

# Slack — X-Slack-Signature + X-Slack-Request-Timestamp (with replay protection)
ConnectorRuby::WebhookVerifier.verify_slack(
  request.raw_post,
  timestamp: request.headers["X-Slack-Request-Timestamp"],
  signature: request.headers["X-Slack-Signature"],
  signing_secret: ENV["SLACK_SIGNING_SECRET"]
  # tolerance: 300  # default; override if your clock skew demands it
)

# LiveChat — shared secret_key embedded IN the JSON body (no header, no HMAC)
ConnectorRuby::WebhookVerifier.verify_livechat(
  request.raw_post,
  expected_secret: ENV["LIVECHAT_WEBHOOK_SECRET"]
)
```

All verifiers return `true`/`false` and use a constant-time comparison internally. Slack verification additionally rejects timestamps outside a 5-minute tolerance window (configurable via `tolerance:`) to prevent replay attacks.

> **Why LiveChat is different:** LiveChat does not sign webhooks with HMAC. Every webhook body contains a `secret_key` field, and verification is a constant-time compare between that field and the shared secret configured in your LiveChat webhook settings. See `WebhookVerifier.verify_livechat` for the production-tested implementation.

## Additional features (v0.2.0)

- **Message builder DSL** — fluent API: `ConnectorRuby::Message.to("+62...").text("Hi").buttons([...]).send_via(wa)`
- **Batch sending** — `BatchSender` with rate limiting for bulk outbound
- **Delivery tracking** — correlate sent message IDs with status webhooks
- **Rich WhatsApp types** — templates, documents, location, contacts, reactions, interactive lists
- **Typing indicators** — `send_typing` / `mark_as_read` where supported

## Error handling

All API failures raise `ConnectorRuby::ApiError` (or its subclasses `AuthenticationError`, `RateLimitError`). Rate limits are automatically retried with exponential backoff; after `http_retries` attempts the error propagates so you can observe and alert.

```ruby
begin
  wa.send_text(to: "+6281...", text: "Hi")
rescue ConnectorRuby::AuthenticationError => e
  # 401 — bad token
rescue ConnectorRuby::RateLimitError => e
  # 429 after retries exhausted
rescue ConnectorRuby::ApiError => e
  # other 4xx/5xx; inspect e.status, e.body, e.response
end
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

## License

MIT
