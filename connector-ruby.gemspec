# frozen_string_literal: true

require_relative "lib/connector_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "connector-ruby"
  spec.version = ConnectorRuby::VERSION
  spec.authors = ["Johannes Dwi Cahyo"]
  spec.email = ["johannes@example.com"]
  spec.summary = "Unified channel messaging SDK for Ruby"
  spec.description = "Framework-agnostic SDK for sending/receiving messages across chat platforms. Supports WhatsApp Cloud API, Telegram Bot API, and more."
  spec.homepage = "https://github.com/johannesdwicahyo/connector-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "lib/**/*.rb",
    "README.md",
    "LICENSE",
    "CHANGELOG.md",
    "Rakefile",
    "connector-ruby.gemspec"
  ]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end
