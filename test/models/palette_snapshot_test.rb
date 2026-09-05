require "test_helper"

module Stripeclub
  class PaletteSnapshotTest < ActiveSupport::TestCase
    setup do
      @pattern = Pattern.create!(name: "Host", slot_count: 2)
    end

    test "a snapshot records the colours as they were when it was taken" do
      snapshot = snapshot_of("#FAF8F4", "#12120F")

      assert_equal [ "#FAF8F4", "#12120F" ], snapshot.palette.colors.map(&:hex)
      assert_equal 2, snapshot.size
    end

    test "a snapshot rebuilds a palette that ranks the way the original did" do
      snapshot = snapshot_of("#12120F", "#FAF8F4", "#808080")

      assert_equal [ "#FAF8F4", "#808080", "#12120F" ], snapshot.palette.ranked.map(&:hex)
    end

    test "a snapshot notes when it was taken" do
      assert_not_nil snapshot_of("#FAF8F4", "#12120F").taken_at
    end

    # The point of holding colours rather than a palette id. Pandatone is
    # another tool with its own editor, and a colorway that re-fetched on every
    # render would change under a design that was finished.
    test "a colour edited in Pandatone is drift" do
      snapshot = snapshot_of("#FAF8F4", "#12120F")

      assert snapshot.drifted_from?(palette("#FAF8F4", "#111111"))
      assert_not snapshot.drifted_from?(palette("#FAF8F4", "#12120F"))
    end

    test "a colour added or removed in Pandatone is drift" do
      snapshot = snapshot_of("#FAF8F4", "#12120F")

      assert snapshot.drifted_from?(palette("#FAF8F4", "#12120F", "#808080"))
      assert snapshot.drifted_from?(palette("#FAF8F4"))
      assert_equal 2, snapshot.size
    end

    # Assigned Slot names a position in the palette, so a palette reordered
    # under a colorway moves colours even though the same colours are still in
    # it. Order is part of what was snapshotted.
    test "a palette reordered in Pandatone is drift" do
      original = palette("#FAF8F4", "#12120F")
      snapshot = Colorway.create!(pattern: @pattern, palette: original).snapshot

      reordered = Pandatone::Palette.new(
        id: original.id, name: original.name, colors: original.colors.reverse
      )

      assert_equal snapshot.palette.colors.map(&:id).sort, reordered.colors.map(&:id).sort
      assert snapshot.drifted_from?(reordered)
    end

    test "drift is flagged and not applied" do
      snapshot = snapshot_of("#FAF8F4", "#12120F")

      snapshot.drifted_from?(palette("#FF0000", "#00FF00"))

      assert_equal [ "#FAF8F4", "#12120F" ], snapshot.reload.palette.colors.map(&:hex)
    end

    private
      def palette(*hexes)
        pandatone_palette(*hexes)
      end

      def snapshot_of(*hexes)
        Colorway.create!(pattern: @pattern, palette: palette(*hexes)).snapshot
      end
  end
end
