class CreateStripeclubPatterns < ActiveRecord::Migration[8.1]
  def change
    create_table :stripeclub_patterns do |t|
      t.string :name, null: false
      t.integer :slot_count, null: false, default: 1
      t.decimal :angle, precision: 7, scale: 3, null: false, default: 90.0
      t.decimal :row_depth, precision: 9, scale: 6, null: false, default: 1.0

      t.timestamps
    end

    create_table :stripeclub_values do |t|
      t.references :pattern, null: false, foreign_key: { to_table: :stripeclub_patterns }
      t.integer :position, null: false

      t.timestamps
    end
    add_index :stripeclub_values, %i[ pattern_id position ], unique: true

    create_table :stripeclub_sequences do |t|
      t.references :pattern, null: false, foreign_key: { to_table: :stripeclub_patterns }, index: { unique: true }

      t.timestamps
    end

    create_table :stripeclub_stripes do |t|
      t.references :sequence, null: false, foreign_key: { to_table: :stripeclub_sequences }
      t.references :value, null: false, foreign_key: { to_table: :stripeclub_values }
      t.integer :position, null: false
      t.decimal :width, precision: 9, scale: 6, null: false

      t.timestamps
    end
    add_index :stripeclub_stripes, %i[ sequence_id position ], unique: true
  end
end
