# connector-ruby Milestones

## Current State (v0.1.0)

- WhatsApp Cloud API: send text, buttons, image + webhook parsing
- Telegram Bot API: send text, buttons, image + webhook parsing
- Unified Event model, HTTP client with retries, HMAC webhook verification
- 18 tests, 42 assertions — all passing

---

## v0.1.1 — Bug Fixes & Hardening

### Fix
- [x] **Telegram webhook verification** — `verify_telegram` returns `true` always; implement `secret_token` header verification via `setWebhook` API
- [x] **Webhook payload crash on missing keys** — `parse_webhook` methods crash on malformed payloads with missing nested keys; add nil guards throughout
- [x] **WhatsApp signature comparison length mismatch** — `secure_compare` fails if signature has different byte length than expected; handle gracefully
- [x] **HTTP retry on 429** — RateLimitError is raised but never retried; add exponential backoff for 429 responses with `Retry-After` header parsing

### Add
- [x] Input validation: reject empty `to`/`chat_id`, enforce WhatsApp 4096 char text limit, Telegram 4096 char limit
- [x] Phone number normalization (strip spaces, ensure `+` prefix for WhatsApp)
- [x] Raw response access on ApiError (`error.response` for debugging)
- [x] Logging hooks (`on_request`, `on_response`, `on_error` callbacks in Configuration)

### Test
- [x] Malformed webhook payloads (nil entry, missing changes, empty messages array)
- [x] HTTP retry logic (timeout → retry → success)
- [x] Rate limit handling (429 → backoff → retry)
- [x] Phone number edge cases (with/without +, spaces, dashes)

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

## v0.3.0 — Webhook Verifiers & LiveChat

> **Reshape note:** The original v0.3.0 plan (Rails integration, Instagram/Discord/Email, advanced features) has been redistributed to v0.4.0 and v0.5.0. This release was retargeted to unblock the omnibot Phase 2.4 channel rollout (`docs/superpowers/plans/2026-04-07-additional-channels.md`).

### Add: Webhook Verifiers
- [ ] `WebhookVerifier.verify_messenger(payload:, signature:, app_secret:)` — HMAC-SHA256, `X-Hub-Signature-256` (#37)
- [ ] `WebhookVerifier.verify_line(payload:, signature:, channel_secret:)` — Base64 HMAC-SHA256, `X-Line-Signature` (#38)
- [ ] `WebhookVerifier.verify_slack(payload:, timestamp:, signature:, signing_secret:, tolerance:)` — v0 signature with replay protection (#39)
- [ ] `WebhookVerifier.verify_livechat(payload:, signature:, client_secret:)` — HMAC-SHA256 (#40)

### Add: Channels
- [ ] **LiveChat (minimal)** — `Channels::LiveChat` with `send_text` + `parse_webhook` via LiveChat Agent API (#41). Buttons/images/rich content intentionally deferred.

### Docs
- [ ] README rewrite — 5-channel coverage, per-channel webhook verification, v0.2.0 feature table (#42)
- [ ] CHANGELOG entry + version bump to 0.3.0 (#43)

### Release
- [ ] Tag, publish to RubyGems.org, bump omnibot pin to `~> 0.3` (#44)

---

## v0.4.0 — Rails Integration

> Deferred from the original v0.3.0 plan. Not a Phase 2.4 blocker because Wicara handles its own Rails wiring; connector-ruby only needs to provide clean transport + verification primitives.

### Add: Rails
- [ ] `ConnectorRuby::Rails::Railtie` — auto-configure from Rails credentials (#17)
- [ ] `ConnectorRuby::Rails::WebhookController` — mountable webhook endpoint at `/webhooks/:channel` (#18)
- [ ] Route generator: `rails generate connector:install` (#19)
- [ ] ActiveJob integration for async message sending (#20)

### Integrate
- [ ] **Omnibot** — Replace hand-written channel adapters (~150 LOC each → ~30 LOC); `ConnectorRuby::Event` → Omnibot internal message format mapper (#29)

---

## v0.5.0 — Channel Expansion & Advanced Features

> Deferred from the original v0.3.0 plan. No current downstream consumer in wicara.dev.

### Add: Channels
- [ ] **Instagram** — `Channels::Instagram` (DM API) (#21)
- [ ] **Discord** — `Channels::Discord` (Bot API, webhook integration) (#22)
- [ ] **Email** — `Channels::Email` via SendGrid/Mailgun (send/receive via webhook) (#23)

### Add: Features
- [ ] **Conversation state** — Track conversation context per user across channels (#24)
- [ ] **Multi-tenancy** — Per-tenant channel credentials (#25)
- [ ] **Message queuing** — Outbox pattern with retry for failed sends (#26)
- [ ] **Webhook signature rotation** — Handle key rotation without downtime (#27)
- [ ] **Channel-specific rich adapters** — Carousels, cards, per-platform rich message types (#28)

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
