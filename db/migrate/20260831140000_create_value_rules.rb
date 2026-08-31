class CreateValueRules < ActiveRecord::Migration[8.1]
  def change
    # One rule per value per colorway, and only where the rule is not the
    # default. Auto-Value-Match is what a value does when nothing has been
    # said about it, so writing a row for it would mean "+" had to remember to
    # write one too, and every colorway would carry n rows saying nothing.
    create_table :value_rules do |t|
      t.references :colorway, null: false, foreign_key: true
      t.references :value, null: false, foreign_key: true

      t.string :kind, null: false, default: "auto_value_match"

      # What the rule needs to resolve, and it differs per kind: a slot index,
      # a subset and a seed, a start and a step. Columns for all of them would
      # be five that are null four fifths of the time.
      t.json :settings, null: false

      t.timestamps

      t.index [ :colorway_id, :value_id ], unique: true
    end
  end
end
