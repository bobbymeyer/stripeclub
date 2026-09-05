class CreateStripeclubColorways < ActiveRecord::Migration[8.1]
  def change
    create_table :stripeclub_colorways do |t|
      t.references :pattern, null: false, foreign_key: { to_table: :stripeclub_patterns }
      t.integer :palette_id, null: false
      t.string :name

      t.timestamps
    end

    create_table :stripeclub_palette_snapshots do |t|
      t.references :colorway, null: false, foreign_key: { to_table: :stripeclub_colorways }, index: { unique: true }
      t.string :palette_name
      t.json :colors, null: false
      t.datetime :taken_at, null: false

      t.timestamps
    end

    create_table :stripeclub_value_rules do |t|
      t.references :colorway, null: false, foreign_key: { to_table: :stripeclub_colorways }
      t.references :value, null: false, foreign_key: { to_table: :stripeclub_values }
      t.string :kind, null: false, default: "auto_value_match"
      t.json :settings, null: false

      t.timestamps
    end
    add_index :stripeclub_value_rules, %i[ colorway_id value_id ], unique: true
  end
end
