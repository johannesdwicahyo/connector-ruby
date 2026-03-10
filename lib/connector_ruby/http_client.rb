# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module ConnectorRuby
  class HttpClient
    def initialize(timeout: nil, retries: nil, open_timeout: nil)
      config = ConnectorRuby.configuration
      @timeout = timeout || config.http_timeout
      @retries = retries || config.http_retries
      @open_timeout = open_timeout || config.http_open_timeout
    end

    def get(url, headers: {})
      request(:get, url, headers: headers)
    end

    def post(url, body:, headers: {})
      request(:post, url, body: body, headers: headers)
    end

    private

    def request(method, url, body: nil, headers: {})
      uri = URI.parse(url)
      attempts = 0

      begin
        attempts += 1
        http = build_http(uri)
        req = build_request(method, uri, body: body, headers: headers)
        response = http.request(req)
        handle_response(response)
      rescue RateLimitError => e
        if attempts < @retries
          sleep(2 ** (attempts - 1))
          retry
        end
        raise
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET => e
        retry if attempts < @retries
        raise ConnectorRuby::Error, "HTTP request failed after #{@retries} attempts: #{e.message}"
      end
    end

    def build_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.read_timeout = @timeout
      http.open_timeout = @open_timeout
      http
    end

    def build_request(method, uri, body: nil, headers: {})
      klass = case method
              when :get then Net::HTTP::Get
              when :post then Net::HTTP::Post
              end

      req = klass.new(uri.request_uri)
      headers.each { |k, v| req[k] = v }
      req["Content-Type"] ||= "application/json"

      if body
        req.body = body.is_a?(String) ? body : JSON.generate(body)
      end

      req
    end

    def handle_response(response)
      body = begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        response.body
      end

      case response.code.to_i
      when 200..299
        body
      when 401
        raise AuthenticationError.new("Authentication failed", status: response.code.to_i, body: body)
      when 429
        raise RateLimitError.new("Rate limited", status: 429, body: body)
      else
        raise ApiError.new("API error: #{response.code}", status: response.code.to_i, body: body)
      end
    end
  end
end
