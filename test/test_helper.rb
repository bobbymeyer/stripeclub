# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("../test/dummy/db/migrate", __dir__) ]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"

# Nothing in the suite is allowed out to the network.
require "webmock/minitest"
WebMock.disable_net_connect!(allow_localhost: true)

ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures/files", __dir__)

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    # A sequence with exactly these widths, in order, one value per stripe.
    #
    # Most of what there is to say about a sequence is about its widths, and
    # the pattern around them is scaffolding — written out in every test it
    # would bury the only number the test is about. The widths are written
    # past validation on purpose: these tests ask whether the sequence refuses
    # them, which it cannot do if the write already did.
    def sequence_of(*widths)
      pattern = Stripeclub::Pattern.create!(name: "Widths", slot_count: widths.size)

      pattern.sequence.stripes.each_with_index do |stripe, index|
        stripe.update_column(:width, widths[index])
      end

      pattern.sequence.tap { |sequence| sequence.stripes.reload }
    end

    # Pandatone, configured and answering over HTTP — the engine's default
    # palette source.
    #
    # Stubbed at the wire rather than below it: what is worth testing about
    # reaching another tool is the request as it goes out and the shape that
    # comes back, and a fake client tests neither.
    def with_pandatone(palettes: {}, url: "https://pandatone.test", token: "sekrit")
      stub_request(:get, "#{url}/api/v1/palettes")
        .to_return(body: palettes.keys.map { |id, name| { id: id, name: name, tags: [] } }.to_json,
          headers: { "Content-Type" => "application/json" })

      palettes.each { |(id, name), hexes| stub_palette(url, id, name, hexes) }

      was = [ Stripeclub.pandatone_url, Stripeclub.pandatone_token, Stripeclub.palette_source ]
      Stripeclub.pandatone_url = url
      Stripeclub.pandatone_token = token
      Stripeclub.palette_source = -> { Stripeclub::Pandatone::Client.configured.palettes_json }
      Stripeclub::Pandatone::Catalog.forget!

      yield
    ensure
      Stripeclub.pandatone_url, Stripeclub.pandatone_token, Stripeclub.palette_source = was
      Stripeclub::Pandatone::Catalog.forget!
    end

    def stub_palette(url, id, name, hexes)
      colors = hexes.each_with_index.map do |hex, index|
        {
          id: (id * 100) + index, name: "#{name.parameterize}-#{index}", hex: hex,
          rgb: { r: hex[1..2].to_i(16), g: hex[3..4].to_i(16), b: hex[5..6].to_i(16) }, tags: []
        }
      end

      stub_request(:get, "#{url}/api/v1/palettes/#{id}")
        .to_return(body: { id: id, name: name, tags: [], colors: colors }.to_json,
          headers: { "Content-Type" => "application/json" })
    end

    # A palette shaped the way Pandatone sends them, built from hexes because
    # the hex is the only part of a colour these tests are ever about.
    def pandatone_palette(*hexes, id: 7, name: "Sample")
      colors = hexes.each_with_index.map do |hex, index|
        Stripeclub::Pandatone::Color.new(
          id: (id * 100) + index, name: "Colour #{index}", hex: hex,
          red: hex[1..2].to_i(16), green: hex[3..4].to_i(16), blue: hex[5..6].to_i(16)
        )
      end

      Stripeclub::Pandatone::Palette.new(id: id, name: name, colors: colors)
    end
  end
end

class ActionDispatch::IntegrationTest
  # The engine's routes, by their own names. The dummy application mounts the
  # engine at /stripeclub, and these helpers already know that.
  include Stripeclub::Engine.routes.url_helpers

  # The door is the host's. The dummy host under test/ opens its screens to a
  # cookie and its API to one token, and every test starts through both:
  # Stripeclub has nothing to say about who gets in. The one test that is
  # about the door signs out first.
  setup do
    sign_in_as
    sign_in_client
  end

  def sign_in_as(_user = nil)
    cookies[:signed_in] = "yes"
  end

  def sign_out
    cookies.delete(:signed_in)
  end

  def sign_in_client(_user = nil)
    @api_token = Dummy::API_TOKEN
  end

  def sign_out_client
    @api_token = nil
  end

  def json
    JSON.parse(response.body)
  end

  %w[ get post patch put delete ].each do |verb|
    define_method(verb) do |path, **options|
      if @api_token
        options[:headers] = { "Authorization" => "Bearer #{@api_token}" }.merge(options[:headers] || {})
      end

      super(path, **options)
    end
  end
end
