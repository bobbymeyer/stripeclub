class CreateStripeclubRowsAndImperfections < ActiveRecord::Migration[8.1]
  def change
    create_table :stripeclub_rows do |t|
      t.references :pattern, null: false, foreign_key: { to_table: :stripeclub_patterns }
      t.integer :position, null: false
      t.decimal :height, precision: 9, scale: 6, null: false
      t.decimal :phase, precision: 9, scale: 6, null: false, default: 0.0
      t.integer :color_offset, null: false, default: 0
      t.boolean :mirrored, null: false, default: false
      t.integer :width_numerator, null: false, default: 1
      t.integer :width_denominator, null: false, default: 1

      t.timestamps
    end
    add_index :stripeclub_rows, %i[ pattern_id position ], unique: true

    create_table :stripeclub_imperfections do |t|
      t.references :pattern, null: false, foreign_key: { to_table: :stripeclub_patterns }, index: { unique: true }
      t.integer :seed, null: false
      t.decimal :wobble, precision: 9, scale: 6, null: false, default: 0.0
      t.decimal :wobble_frequency, precision: 9, scale: 6, null: false, default: 0.02
      t.integer :wobble_octaves, null: false, default: 2
      t.decimal :variance, precision: 9, scale: 6, null: false, default: 0.0
      t.decimal :texture, precision: 9, scale: 6, null: false, default: 0.0
      t.decimal :texture_frequency, precision: 9, scale: 6, null: false, default: 0.8

      t.timestamps
    end
  end
end
