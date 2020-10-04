# frozen_string_literal: true

class Webfinger
  class Error < StandardError; end

  class Response
    def initialize(body)
      @json = Oj.parse(body, mode: :strict)
    end

    def subject
      @json['subject']
    end

    def link(rel, attribute)
      links.dig(rel, attribute)
    end

    private

    def links
      @links ||= @json['links'].map { |link| [link['rel'], link] }.to_h
    end
  end

  def initialize(uri)
    @uri    = uri
    @domain = uri.split('@').last
  end

  def perform
    body = request.perform do |res|
      if res.code == 200
        res.body_with_limit
      else
        raise Webfinger::Error, "Request for #{@uri} returned HTTP #{res.code}"
      end
    end

    Response.new(body)
  rescue Oj::ParseError
    raise Webfinger::Error, "Invalid JSON in response for #{@uri}"
  end

  private

  def request
    Request.new(:get, standard_url).add_headers('Accept' => 'application/jrd+json, application/json')
  end

  def standard_url
    "https://#{@domain}/.well-known/webfinger?resource=#{@uri}"
  end
end
