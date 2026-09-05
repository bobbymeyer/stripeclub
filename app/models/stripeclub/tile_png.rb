require "chunky_png"

# One tile, rasterised.
#
# A PNG has no geometry, so the pattern is sampled rather than drawn: for each
# pixel, how far along the repeat it is and therefore which stripe it is
# under. That is the same shape the SVG states as rects, said the other way
# round, and it is the only way round a raster can be given.
#
# Sampled more than once per pixel, because a stripe edge at an angle crosses
# a pixel rather than landing between two. One sample gives a staircase; a
# grid of them gives the edge its share of the pixel.
module Stripeclub
  class TilePng
    # Two by two is four samples a pixel and about a quarter of a pixel of
    # error left on an edge, which at any size a tile is exported at is under
    # what a screen can show. Three by three costs more than twice as much for
    # a difference nobody has been able to point at.
    SAMPLES = 2

    # A tile is a tile. Past this it is a poster of one, and it is a poster
    # somebody waited on while Ruby wrote it a pixel at a time. The limit lives
    # here rather than in whatever asked, because it is a fact about writing
    # pixels one at a time and not about any one caller.
    MOST_PIXELS = 2048

    def initialize(dressing, period: SvgPattern::PERIOD, scale: 1, samples: SAMPLES)
      @tile = Tile.new(dressing, period: period)
      @dressing = dressing
      @samples = samples
      @scale = [ scale.to_f, MOST_PIXELS / [ @tile.width, @tile.height ].max ].min
    end

    def width
      @tile.width.*(@scale).round
    end

    def height
      @tile.height.*(@scale).round
    end

    def to_blob
      image = ChunkyPNG::Image.new(width, height)

      height.times do |row|
        width.times { |column| image[column, row] = ChunkyPNG::Color.rgb(*averaged(column, row)) }
      end

      image.to_blob
    end

    private
      # The colour a stripe resolves to does not change from pixel to pixel, and
      # asking a rule a million times would be a million times more work than
      # asking it once per stripe per band.
      def swatches
        @swatches ||= @tile.bands.map do |band|
          @tile.stripes.map { |stripe| @dressing.color_for(stripe, offset: band.offset).channels }
        end
      end

      def averaged(column, row)
        totals = [ 0, 0, 0 ]

        @samples.times do |down|
          @samples.times do |across|
            channels = sample(column + ((across + 0.5) / @samples), row + ((down + 0.5) / @samples))

            3.times { |channel| totals[channel] += channels[channel] }
          end
        end

        totals.map { |total| total / (@samples * @samples) }
      end

      def sample(column, row)
        x, y = column / @scale, row / @scale
        band = @tile.band_at(y)

        swatches[band.index][@tile.stripe_index_for(@tile.phase_in(band, x, y))]
      end
  end
end
