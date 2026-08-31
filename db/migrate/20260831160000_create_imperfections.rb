class CreateImperfections < ActiveRecord::Migration[8.1]
  def change
    # Round two. Optional, and separate from the pattern on purpose: a clean
    # pattern is the normal case, and nine columns that are zero most of the
    # time would make the exception look like the rule.
    #
    # Nothing here touches the composition. The widths in the sequence stay
    # what someone typed; these are applied when the pattern is drawn, which
    # is what keeps it editable underneath.
    create_table :imperfections do |t|
      t.references :pattern, null: false, foreign_key: true, index: { unique: true }

      # --- Wobbly edges: feTurbulence into feDisplacementMap ---------------

      # How far an edge is pushed, as a proportion of the repeat.
      t.decimal :wobble, precision: 9, scale: 6, null: false, default: 0

      # How close together the wobbles are, in turbulence's own units.
      t.decimal :wobble_frequency, precision: 9, scale: 6, null: false, default: 0.02
      t.integer :wobble_octaves, null: false, default: 2

      # --- Width variance: seeded jitter, still summing to one -------------

      # How much a width may be off, as a proportion of itself.
      t.decimal :variance, precision: 9, scale: 6, null: false, default: 0

      # --- Texture: a tiling noise multiplied over the whole ---------------
      t.decimal :texture, precision: 9, scale: 6, null: false, default: 0
      t.decimal :texture_frequency, precision: 9, scale: 6, null: false, default: 0.8

      # One seed for the lot. Imperfection that changed on every render would
      # not be a pattern, and three seeds would be three things to write down
      # to get the same picture back.
      t.integer :seed, null: false

      t.timestamps
    end
  end
end
