# connector-ruby Milestones

## Current State (v0.1.0)

- WhatsApp Cloud API: send text, buttons, image + webhook parsing
- Telegram Bot API: send text, buttons, image + webhook parsing
- Unified Event model, HTTP client with retries, HMAC webhook verification
- 18 tests, 42 assertions — all passing

---

## v0.1.1 — Bug Fixes & Hardening

### Fix
- [ ] **Telegram webhook verification** — `verify_telegram` returns `true` always; implement `secret_token` header verification via `setWebhook` API
- [ ] **Webhook payload crash on missing keys** — `parse_webhook` methods crash on malformed payloads with missing nested keys; add nil guards throughout
- [ ] **WhatsApp signature comparison length mismatch** — `secure_compare` fails if signature has different byte length than expected; handle gracefully
- [ ] **HTTP retry on 429** — RateLimitError is raised but never retried; add exponential backoff for 429 responses with `Retry-After` header parsing

### Add
- [ ] Input validation: reject empty `to`/`chat_id`, enforce WhatsApp 4096 char text limit, Telegram 4096 char limit
- [ ] Phone number normalization (strip spaces, ensure `+` prefix for WhatsApp)
- [ ] Raw response access on ApiError (`error.response` for debugging)
- [ ] Logging hooks (`on_request`, `on_response`, `on_error` callbacks in Configuration)

### Test
- [ ] Malformed webhook payloads (nil entry, missing changes, empty messages array)
- [ ] HTTP retry logic (timeout → retry → success)
- [ ] Rate limit handling (429 → backoff → retry)
- [ ] Phone number edge cases (with/without +, spaces, dashes)

---

## v0.2.0 — New Channels & Message Types

### Add: Channels
- [ ] **Facebook Messenger** — `Channels::Messenger` (send/receive text, buttons, quick replies, templates)
- [ ] **LINE Messaging API** — `Channels::Line` (send/receive text, flex messages, rich menus)
- [ ] **Slack Web API** — `Channels::Slack` (send/receive text, blocks, attachments)

### Add: Message Types
- [ ] **WhatsApp templates** — `send_template(to:, template_name:, language:, components:)`
- [ ] **Document/file sending** — `send_document(to:, url:, filename:)` for WhatsApp + Telegram
- [ ] **Location sharing** — `send_location(to:, latitude:, longitude:, name:)`
- [ ] **Contact cards** — `send_contact(to:, name:, phone:)`
- [ ] **Reactions** — `send_reaction(to:, message_id:, emoji:)` for WhatsApp
- [ ] **Interactive lists** — `send_list(to:, body:, sections:)` for WhatsApp

### Add: Features
- [ ] **Message builder DSL** — Fluent API: `Message.to("+62...").text("Hi").buttons([...]).send!`
- [ ] **Delivery tracking** — Correlate sent message IDs with status webhooks
- [ ] **Typing indicators** — `send_typing(chat_id:)` for Telegram, `mark_as_read` for WhatsApp
- [ ] **Batch sending** — `send_batch(messages)` with rate limiting

### Test
- [ ] Each new channel: send text/buttons/image, parse webhooks
- [ ] New message types: document, location, contact, template
- [ ] Cross-channel event normalization (same message from WA vs TG vs Messenger produces same Event)

---

## v0.3.0 — Rails Integration & Advanced Features

### Add: Rails
- [ ] `ConnectorRuby::Rails::Railtie` — auto-configure from Rails credentials
- [ ] `ConnectorRuby::Rails::WebhookController` — mountable webhook endpoint at `/webhooks/:channel`
- [ ] Route generator: `rails generate connector:install`
- [ ] ActiveJob integration for async message sending

### Add: Channels
- [ ] **Instagram** — `Channels::Instagram` (DM API)
- [ ] **Discord** — `Channels::Discord` (Bot API, webhook integration)
- [ ] **Email** — `Channels::Email` via SendGrid/Mailgun (send/receive via webhook)

### Add: Features
- [ ] **Conversation state** — Track conversation context per user across channels
- [ ] **Multi-tenancy** — Per-tenant channel credentials
- [ ] **Message queuing** — Outbox pattern with retry for failed sends
- [ ] **Webhook signature rotation** — Handle key rotation without downtime
- [ ] **Channel-specific adapters** — Rich message types per platform (carousel, cards, etc.)

### Integrate
- [ ] **Omnibot** — Replace hand-written channel adapters (~150 LOC each → ~30 LOC)
- [ ] `ConnectorRuby::Event` → Omnibot internal message format mapper

---

## v1.0.0 — Production Ready

### Refine
- [ ] API stability guarantee (semantic versioning, deprecation policy)
- [ ] Comprehensive documentation with per-channel guides
- [ ] Performance benchmarks (messages/sec per channel)
- [ ] Thread safety audit for concurrent sends
- [ ] Connection pooling for HTTP client
- [ ] Circuit breaker pattern for channel outages
- [ ] Metrics/instrumentation (ActiveSupport::Notifications compatible)
