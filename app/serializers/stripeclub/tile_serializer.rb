# The wire format for a tile's measurements. Key order here is the key order
# downstream tools see, and the contract test pins it, so treat this file as
# the interface.
module Stripeclub
  module TileSerializer
    module_function

    def one(tile)
      {
        width: tile.width.round(4),
        height: tile.height.round(4),
        tiles: tile.tiles?,
        note: tile.note
      }
    end
  end
end
