require "net/http"

# Pandatone's v1 API, which is versioned from its first commit precisely so a
# tool like this one can depend on it.
class Pandatone::Client
  PREFIX = "api/v1".freeze
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 15

  def self.configured
    settings = Rails.application.config.x.pandatone

    new(url: settings.url, token: settings.token)
  end

  def initialize(url:, token:, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT)
    raise Pandatone::Error, "no Pandatone url is configured" if url.blank?

    @base = URI.parse(url)
    @token = token
    @open_timeout, @read_timeout = open_timeout, read_timeout
  end

  # Every palette Pandatone has, with its colours.
  #
  # A request per palette, because the index carries id, name and tags and no
  # colours — and every filter Stripeclub applies is a question about the
  # colours: how many there are, and how light each one is. The handoff says
  # fetch once per session and filter locally, so this is paid once and the
  # catalogue answers from memory afterwards.
  #
  # The way out is a change to Pandatone rather than a cleverer client: a
  # colour count on the summary would settle the "at least n colours" filter
  # without any of these, and an index that could be asked to include colours
  # would settle all of it. That is the "driven by need" the handoff leaves
  # the query parameters to, and this is the need.
  def palettes
    get(PREFIX, "palettes").map { |summary| palette(summary["id"]) }
  end

  def palette(id)
    Pandatone::Palette.from_json(get(PREFIX, "palettes", id.to_s))
  end

  private
    def get(*segments)
      response = fetch(path_for(*segments))

      case response
      when Net::HTTPSuccess then parse(response.body)
      when Net::HTTPUnauthorized then raise Pandatone::Unauthorized, "#{@base.host} refused the token"
      when Net::HTTPNotFound then raise Pandatone::NotFound, path_for(*segments)
      else raise Pandatone::Error, "#{@base.host} answered #{response.code}"
      end
    end

    def path_for(*segments)
      [ @base.path.chomp("/"), *segments ].join("/")
    end

    def fetch(path)
      request = Net::HTTP::Get.new(path)
      request["Authorization"] = "Bearer #{@token}"
      request["Accept"] = "application/json"

      http.request(request)
    rescue SystemCallError, Net::OpenTimeout, Net::ReadTimeout, SocketError, OpenSSL::SSL::SSLError => e
      raise Pandatone::Unreachable, "#{@base.host}: #{e.message}"
    end

    def http
      Net::HTTP.new(@base.host, @base.port).tap do |http|
        http.use_ssl = @base.scheme == "https"
        http.open_timeout = @open_timeout
        http.read_timeout = @read_timeout
      end
    end

    # A 200 carrying a proxy's error page is still not a catalogue.
    def parse(body)
      JSON.parse(body)
    rescue JSON::ParserError => e
      raise Pandatone::Error, "#{@base.host} answered with something that is not json: #{e.message}"
    end
end
