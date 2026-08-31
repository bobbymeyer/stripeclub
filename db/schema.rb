# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_31_140000) do
  create_table "colorways", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "palette_id", null: false
    t.integer "pattern_id", null: false
    t.datetime "updated_at", null: false
    t.index ["pattern_id"], name: "index_colorways_on_pattern_id"
  end

  create_table "palette_snapshots", force: :cascade do |t|
    t.json "colors", null: false
    t.integer "colorway_id", null: false
    t.datetime "created_at", null: false
    t.string "palette_name"
    t.datetime "taken_at", null: false
    t.datetime "updated_at", null: false
    t.index ["colorway_id"], name: "index_palette_snapshots_on_colorway_id", unique: true
  end

  create_table "patterns", force: :cascade do |t|
    t.decimal "angle", precision: 7, scale: 3, default: "90.0", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "slot_count", default: 1, null: false
    t.datetime "updated_at", null: false
  end

  create_table "sequences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "pattern_id", null: false
    t.datetime "updated_at", null: false
    t.index ["pattern_id"], name: "index_sequences_on_pattern_id", unique: true
  end

  create_table "stripes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.integer "sequence_id", null: false
    t.datetime "updated_at", null: false
    t.integer "value_id", null: false
    t.decimal "width", precision: 9, scale: 6, null: false
    t.index ["sequence_id", "position"], name: "index_stripes_on_sequence_id_and_position", unique: true
    t.index ["sequence_id"], name: "index_stripes_on_sequence_id"
    t.index ["value_id"], name: "index_stripes_on_value_id"
  end

  create_table "value_rules", force: :cascade do |t|
    t.integer "colorway_id", null: false
    t.datetime "created_at", null: false
    t.string "kind", default: "auto_value_match", null: false
    t.json "settings", null: false
    t.datetime "updated_at", null: false
    t.integer "value_id", null: false
    t.index ["colorway_id", "value_id"], name: "index_value_rules_on_colorway_id_and_value_id", unique: true
    t.index ["colorway_id"], name: "index_value_rules_on_colorway_id"
    t.index ["value_id"], name: "index_value_rules_on_value_id"
  end

  create_table "values", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "pattern_id", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["pattern_id", "position"], name: "index_values_on_pattern_id_and_position", unique: true
    t.index ["pattern_id"], name: "index_values_on_pattern_id"
  end

  add_foreign_key "colorways", "patterns"
  add_foreign_key "palette_snapshots", "colorways"
  add_foreign_key "sequences", "patterns"
  add_foreign_key "stripes", "sequences"
  add_foreign_key "stripes", "values"
  add_foreign_key "value_rules", "colorways"
  add_foreign_key "value_rules", "values"
  add_foreign_key "values", "patterns"
end
