ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Nothing in the suite is allowed out to the network. Localhost stays open
# because the system tests drive a browser against a server on it.
require "webmock/minitest"
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # A sequence with exactly these widths, in order, one value per stripe.
    #
    # Most of what there is to say about a sequence is about its widths, and
    # the pattern around them is scaffolding — written out in every test it
    # would bury the only number the test is about. The widths are written
    # past validation on purpose: these tests ask whether the sequence refuses
    # them, which it cannot do if the write already did.
    def sequence_of(*widths)
      pattern = Pattern.create!(name: "Widths", slot_count: widths.size)

      pattern.sequence.stripes.each_with_index do |stripe, index|
        stripe.update_column(:width, widths[index])
      end

      pattern.sequence.tap { |sequence| sequence.stripes.reload }
    end

    # Pandatone, configured and answering.
    #
    # Stubbed at the wire rather than below it: what is worth testing about
    # reaching another tool is the request as it goes out and the shape that
    # comes back, and a fake client tests neither.
    def with_pandatone(palettes: {}, url: "https://pandatone.test", token: "sekrit")
      stub_request(:get, "#{url}/api/v1/palettes")
        .to_return(body: palettes.keys.map { |id, name| { id: id, name: name, tags: [] } }.to_json,
          headers: { "Content-Type" => "application/json" })

      palettes.each { |(id, name), hexes| stub_palette(url, id, name, hexes) }

      was = Rails.application.config.x.pandatone.to_h
      Rails.application.config.x.pandatone.url = url
      Rails.application.config.x.pandatone.token = token
      Pandatone::Catalog.forget!

      yield
    ensure
      Rails.application.config.x.pandatone.url = was[:url]
      Rails.application.config.x.pandatone.token = was[:token]
      Pandatone::Catalog.forget!
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
        Pandatone::Color.new(
          id: (id * 100) + index, name: "Colour #{index}", hex: hex,
          red: hex[1..2].to_i(16), green: hex[3..4].to_i(16), blue: hex[5..6].to_i(16)
        )
      end

      Pandatone::Palette.new(id: id, name: name, colors: colors)
    end
  end
end
