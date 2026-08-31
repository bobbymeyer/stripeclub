# The four tables are one structure and mean nothing apart: a pattern with no
# values has no slots to draw, and a sequence with no stripes has no repeat.
# They arrive together.
class CreatePatternStructure < ActiveRecord::Migration[8.1]
  def change
    create_table :patterns do |t|
      t.string :name, null: false

      # n. How many slots the structure has, not how many colours it will get.
      t.integer :slot_count, null: false, default: 1

      # Degrees, folded into [0, 180): stripes at 30 and at 210 are the same
      # stripes. Decimal rather than integer because Snap To Tiling lands on
      # arctangents of small ratios, which are not whole numbers of degrees.
      t.decimal :angle, precision: 7, scale: 3, null: false, default: 90

      t.timestamps
    end

    # One per slot. A rank and nothing else — no luminance, no colour: what a
    # rank resolves to is a property of the palette a colorway applies, and
    # storing it here would freeze an answer to a question not yet asked.
    create_table :values do |t|
      t.references :pattern, null: false, foreign_key: true
      t.integer :position, null: false

      t.timestamps

      t.index [ :pattern_id, :position ], unique: true
    end

    # The repeat unit along the stripe normal. One per pattern.
    create_table :sequences do |t|
      t.references :pattern, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end

    create_table :stripes do |t|
      t.references :sequence, null: false, foreign_key: true
      t.references :value, null: false, foreign_key: true

      # A proportion of the repeat. Six places, because the widths of a
      # sequence have to sum to one and the rule that checks it has to know
      # how much rounding the storage forces before it can tell rounding from
      # a sequence that is genuinely short.
      t.decimal :width, precision: 9, scale: 6, null: false

      t.integer :position, null: false

      t.timestamps

      t.index [ :sequence_id, :position ], unique: true
    end
  end
end
