# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-04-11

Reshape release — the original v0.3.0 Rails-integration plan was redistributed
to v0.4.0 (Rails integration) and v0.5.0 (channel expansion + advanced features)
to unblock the downstream omnibot Phase 2.4 channel rollout, which needed
webhook verification for all shipped channels plus a LiveChat transport.

### Added
- `WebhookVerifier.verify_messenger(payload, signature:, app_secret:)` — HMAC-SHA256 signature verification for Meta Messenger webhooks (`X-Hub-Signature-256` header).
- `WebhookVerifier.verify_line(payload, signature:, channel_secret:)` — Base64 HMAC-SHA256 signature verification for LINE Messaging API webhooks (`X-Line-Signature` header), with case-sensitive comparison.
- `WebhookVerifier.verify_slack(payload, timestamp:, signature:, signing_secret:, tolerance: 300)` — Slack v0 signature verification with replay protection. Rejects requests whose `X-Slack-Request-Timestamp` is outside the tolerance window (default 5 minutes).
- `WebhookVerifier.verify_livechat(payload, expected_secret:)` — shared-secret verification for LiveChat webhooks. LiveChat does not use HMAC; it embeds a `secret_key` field in the webhook body.
- `Channels::LiveChat` — minimal LiveChat (livechatinc.com / text.com) Agent API support: `send_text` + `parse_webhook`. Basic auth with a PAT (`base64(account_id:region:pat_value)`) and optional `X-Region` header.
- `Configuration#livechat_pat` and `Configuration#livechat_region`.
- `WebhookVerifier.secure_compare` now accepts `case_sensitive:` keyword (default `false` for hex signatures; pass `true` for Base64 or shared-secret comparisons).
- Runtime dependency on the `base64` gem so `verify_line` works on Ruby 3.4+ (where `base64` was removed from default gems).

### Changed
- README rewritten to cover all 6 channels with per-channel webhook verification examples.

### Notes
- Rails integration work (Railtie, mountable WebhookController, install generator, ActiveJob integration, omnibot helper) has been moved to milestone v0.4.0.
- Instagram, Discord, Email, conversation state, multi-tenancy, outbox pattern, signature rotation, and rich message adapters have been moved to milestone v0.5.0.

## [0.2.0] - 2026-03-17

### Added
- **Channels:** Facebook Messenger (`Channels::Messenger`), LINE Messaging API (`Channels::Line`), Slack Web API (`Channels::Slack`). Each supports `send_text`, `send_buttons`, `send_image`, and `parse_webhook`, plus channel-specific rich types (Messenger quick replies, LINE flex, Slack blocks).
- **WhatsApp rich message types:** templates, documents, location, contacts, reactions, interactive lists.
- **Message builder DSL:** fluent API for constructing outbound messages.
- **Batch sending:** `BatchSender` with rate limiting.
- **Delivery tracking:** correlate sent message IDs with status webhooks.
- **Typing indicators** and `mark_as_read` where the platform supports them.

## [0.1.1] - 2026-03-09

### Fixed
- Telegram webhook verification now enforces the `X-Telegram-Bot-Api-Secret-Token` header set via `setWebhook`.
- `parse_webhook` no longer crashes on malformed payloads with missing nested keys; nil guards throughout.
- WhatsApp signature comparison handles differing byte lengths gracefully.
- HTTP retry now applies exponential backoff for 429 responses (previously `RateLimitError` was raised but never retried).

### Added
- Input validation: reject empty `to`/`chat_id`, enforce WhatsApp/Telegram 4096-char text limits.
- Phone number normalization for WhatsApp (strip spaces, enforce `+` prefix).
- Raw response access on `ApiError` (`error.response`).
- Logging hooks: `on_request`, `on_response`, `on_error` callbacks in `Configuration`.

## [0.1.0] - 2026-03-09

- Initial release.
- WhatsApp Cloud API support (send text, buttons, image; parse webhooks).
- Telegram Bot API support (send text, buttons, image; parse webhooks).
- Unified `Event` model for normalized inbound messages.
- Webhook signature verification (WhatsApp HMAC-SHA256).
- HTTP client with retry and timeout support.
- Configuration DSL.
