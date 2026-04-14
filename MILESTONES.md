# connector-ruby — Milestones

> **Source of truth:** https://github.com/johannesdwicahyo/connector-ruby/milestones
> **Last synced:** 2026-04-14

This file mirrors the GitHub milestones for this repo. Edit the milestone or issues on GitHub and re-sync, do not hand-edit.

## v1.0.0 (**open**)

_Production ready: API stability guarantee, comprehensive documentation, performance benchmarks, thread safety, connection pooling, circuit breaker, metrics/instrumentation_

- [ ] #30 API stability guarantee and deprecation policy
- [ ] #31 Comprehensive documentation with per-channel guides
- [ ] #32 Performance benchmarks (messages/sec per channel)
- [ ] #33 Thread safety audit for concurrent sends
- [ ] #34 Connection pooling for HTTP client
- [ ] #35 Circuit breaker pattern for channel outages
- [ ] #36 Metrics and instrumentation (ActiveSupport::Notifications)

## v0.5.0 (**open**)

_Channel expansion + advanced features — Instagram, Discord, Email, conversation state, multi-tenancy, outbox pattern, signature rotation, rich adapters_

- [ ] #21 Add Instagram DM channel
- [ ] #22 Add Discord channel
- [ ] #23 Add Email channel via SendGrid/Mailgun
- [ ] #24 Add conversation state tracking
- [ ] #25 Add multi-tenancy support
- [ ] #26 Add message queuing with outbox pattern
- [ ] #27 Add webhook signature rotation support
- [ ] #28 Add channel-specific rich message adapters

## v0.4.0 (**open**)

_Rails integration release — Railtie, mountable WebhookController, install generator, ActiveJob integration, omnibot helper_

- [ ] #17 Add Rails Railtie for auto-configuration
- [ ] #18 Add mountable WebhookController
- [ ] #19 Add Rails install generator
- [ ] #20 Add ActiveJob integration for async sending
- [ ] #29 Omnibot integration

## v0.3.0 (**closed** — released 2026-04-11)

_Webhook verifiers for Messenger/LINE/Slack/LiveChat + minimal LiveChat channel. Reshaped from the original "Rails integration" plan to unblock omnibot Phase 2.4. Rails work moved to v0.4.0; channel expansion + advanced features moved to v0.5.0._

- [x] #37 Add WebhookVerifier.verify_messenger
- [x] #38 Add WebhookVerifier.verify_line
- [x] #39 Add WebhookVerifier.verify_slack
- [x] #40 Add WebhookVerifier.verify_livechat
- [x] #41 Add Channels::LiveChat (minimal)
- [x] #42 Rewrite README for 5-channel coverage
- [x] #43 Update CHANGELOG and bump version to 0.3.0
- [x] #44 Release connector-ruby v0.3.0

## v0.2.0 (**closed**)

_New channels (Facebook Messenger, LINE, Slack) & message types (templates, documents, location, contacts, reactions, lists, builder DSL, delivery tracking, typing indicators, batch sending)_

- [x] #1 Add Facebook Messenger channel
- [x] #2 Add LINE Messaging API channel
- [x] #3 Add Slack Web API channel
- [x] #4 Add WhatsApp template message support
- [x] #5 Add document/file sending
- [x] #6 Add location sharing
- [x] #7 Add contact card sending
- [x] #8 Add message reactions for WhatsApp
- [x] #9 Add interactive lists for WhatsApp
- [x] #10 Add message builder DSL
- [x] #11 Add delivery tracking
- [x] #12 Add typing indicators
- [x] #13 Add batch sending with rate limiting
- [x] #14 Tests for new channels (Messenger, LINE, Slack)
- [x] #15 Tests for new message types
- [x] #16 Tests for cross-channel event normalization

## v0.1.1 (**closed**)

_Bug fixes & hardening: Telegram webhook verification, payload crash fixes, WhatsApp signature handling, HTTP 429 retry, input validation, phone normalization, logging hooks_

_No issues._ (0 open, 0 closed reported)
