class CreateColorways < ActiveRecord::Migration[8.1]
  def change
    create_table :colorways do |t|
      t.references :pattern, null: false, foreign_key: true
      t.string :name

      # Pandatone's id for the palette, kept so a colorway can be re-checked
      # against it. It is a reference to another tool's record and not a
      # foreign key: Pandatone is over HTTP and may be unreachable, and a
      # colorway has to render anyway.
      t.integer :palette_id, null: false

      t.timestamps
    end

    # The colours as they were when the palette was chosen.
    #
    # Held rather than fetched, because Pandatone is a tool with its own
    # editor and a colorway that re-resolved on every render would change
    # under a design that was finished. What Pandatone has done since is
    # drift, which is reported and never applied.
    create_table :palette_snapshots do |t|
      t.references :colorway, null: false, foreign_key: true, index: { unique: true }
      t.string :palette_name

      # Shaped exactly as Pandatone sends them, so reading a snapshot back is
      # the same code path as reading the wire and there is no second parser
      # to disagree with the first.
      t.json :colors, null: false

      t.datetime :taken_at, null: false

      t.timestamps
    end
  end
end
