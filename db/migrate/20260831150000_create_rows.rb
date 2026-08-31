class CreateRows < ActiveRecord::Migration[8.1]
  def change
    # How tall the whole row block is, measured in repeats. The rows divide
    # this between them, so a block one repeat deep with four rows gives bands
    # a quarter of a repeat each.
    add_column :patterns, :row_depth, :decimal, precision: 9, scale: 6, null: false, default: 1

    # Optional. A pattern without rows is a pattern; these are what make the
    # vertical seam that lets an axis-aligned tile carry any angle.
    create_table :rows do |t|
      t.references :pattern, null: false, foreign_key: true
      t.integer :position, null: false

      # A proportion of the block, so the heights sum to one — the same rule
      # the stripe widths keep, and for the same reason.
      t.decimal :height, precision: 9, scale: 6, null: false

      # --- The four transforms ---------------------------------------------

      # Along the stripe normal, as a proportion of the repeat. Half a period
      # per row is what makes the lightning.
      t.decimal :phase, precision: 9, scale: 6, null: false, default: 0

      # How far along the palette this row's colours move.
      t.integer :color_offset, null: false, default: 0

      # θ becomes 180 − θ for this row: the stripes lean the other way.
      t.boolean :mirrored, null: false, default: false

      # A ratio rather than a decimal, because the tile has to be a whole
      # number of every row's repeat and that is a question about fractions.
      # A decimal would make it a question about floating point.
      t.integer :width_numerator, null: false, default: 1
      t.integer :width_denominator, null: false, default: 1

      t.timestamps

      t.index [ :pattern_id, :position ], unique: true
    end
  end
end
