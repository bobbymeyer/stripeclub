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

ActiveRecord::Schema[8.1].define(version: 2026_09_05_100003) do
  create_table "colorways", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "palette_id", null: false
    t.integer "pattern_id", null: false
    t.datetime "updated_at", null: false
    t.index ["pattern_id"], name: "index_colorways_on_pattern_id"
  end

  create_table "imperfections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "pattern_id", null: false
    t.integer "seed", null: false
    t.decimal "texture", precision: 9, scale: 6, default: "0.0", null: false
    t.decimal "texture_frequency", precision: 9, scale: 6, default: "0.8", null: false
    t.datetime "updated_at", null: false
    t.decimal "variance", precision: 9, scale: 6, default: "0.0", null: false
    t.decimal "wobble", precision: 9, scale: 6, default: "0.0", null: false
    t.decimal "wobble_frequency", precision: 9, scale: 6, default: "0.02", null: false
    t.integer "wobble_octaves", default: 2, null: false
    t.index ["pattern_id"], name: "index_imperfections_on_pattern_id", unique: true
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
    t.decimal "row_depth", precision: 9, scale: 6, default: "1.0", null: false
    t.integer "slot_count", default: 1, null: false
    t.datetime "updated_at", null: false
  end

  create_table "rows", force: :cascade do |t|
    t.integer "color_offset", default: 0, null: false
    t.datetime "created_at", null: false
    t.decimal "height", precision: 9, scale: 6, null: false
    t.boolean "mirrored", default: false, null: false
    t.integer "pattern_id", null: false
    t.decimal "phase", precision: 9, scale: 6, default: "0.0", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.integer "width_denominator", default: 1, null: false
    t.integer "width_numerator", default: 1, null: false
    t.index ["pattern_id", "position"], name: "index_rows_on_pattern_id_and_position", unique: true
    t.index ["pattern_id"], name: "index_rows_on_pattern_id"
  end

  create_table "sequences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "pattern_id", null: false
    t.datetime "updated_at", null: false
    t.index ["pattern_id"], name: "index_sequences_on_pattern_id", unique: true
  end

  create_table "stripeclub_colorways", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "palette_id", null: false
    t.integer "pattern_id", null: false
    t.datetime "updated_at", null: false
    t.index ["pattern_id"], name: "index_stripeclub_colorways_on_pattern_id"
  end

  create_table "stripeclub_imperfections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "pattern_id", null: false
    t.integer "seed", null: false
    t.decimal "texture", precision: 9, scale: 6, default: "0.0", null: false
    t.decimal "texture_frequency", precision: 9, scale: 6, default: "0.8", null: false
    t.datetime "updated_at", null: false
    t.decimal "variance", precision: 9, scale: 6, default: "0.0", null: false
    t.decimal "wobble", precision: 9, scale: 6, default: "0.0", null: false
    t.decimal "wobble_frequency", precision: 9, scale: 6, default: "0.02", null: false
    t.integer "wobble_octaves", default: 2, null: false
    t.index ["pattern_id"], name: "index_stripeclub_imperfections_on_pattern_id", unique: true
  end

  create_table "stripeclub_palette_snapshots", force: :cascade do |t|
    t.json "colors", null: false
    t.integer "colorway_id", null: false
    t.datetime "created_at", null: false
    t.string "palette_name"
    t.datetime "taken_at", null: false
    t.datetime "updated_at", null: false
    t.index ["colorway_id"], name: "index_stripeclub_palette_snapshots_on_colorway_id", unique: true
  end

  create_table "stripeclub_patterns", force: :cascade do |t|
    t.decimal "angle", precision: 7, scale: 3, default: "90.0", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.decimal "row_depth", precision: 9, scale: 6, default: "1.0", null: false
    t.integer "slot_count", default: 1, null: false
    t.datetime "updated_at", null: false
  end

  create_table "stripeclub_rows", force: :cascade do |t|
    t.integer "color_offset", default: 0, null: false
    t.datetime "created_at", null: false
    t.decimal "height", precision: 9, scale: 6, null: false
    t.boolean "mirrored", default: false, null: false
    t.integer "pattern_id", null: false
    t.decimal "phase", precision: 9, scale: 6, default: "0.0", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.integer "width_denominator", default: 1, null: false
    t.integer "width_numerator", default: 1, null: false
    t.index ["pattern_id", "position"], name: "index_stripeclub_rows_on_pattern_id_and_position", unique: true
    t.index ["pattern_id"], name: "index_stripeclub_rows_on_pattern_id"
  end

  create_table "stripeclub_sequences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "pattern_id", null: false
    t.datetime "updated_at", null: false
    t.index ["pattern_id"], name: "index_stripeclub_sequences_on_pattern_id", unique: true
  end

  create_table "stripeclub_stripes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.integer "sequence_id", null: false
    t.datetime "updated_at", null: false
    t.integer "value_id", null: false
    t.decimal "width", precision: 9, scale: 6, null: false
    t.index ["sequence_id", "position"], name: "index_stripeclub_stripes_on_sequence_id_and_position", unique: true
    t.index ["sequence_id"], name: "index_stripeclub_stripes_on_sequence_id"
    t.index ["value_id"], name: "index_stripeclub_stripes_on_value_id"
  end

  create_table "stripeclub_value_rules", force: :cascade do |t|
    t.integer "colorway_id", null: false
    t.datetime "created_at", null: false
    t.string "kind", default: "auto_value_match", null: false
    t.json "settings", null: false
    t.datetime "updated_at", null: false
    t.integer "value_id", null: false
    t.index ["colorway_id", "value_id"], name: "index_stripeclub_value_rules_on_colorway_id_and_value_id", unique: true
    t.index ["colorway_id"], name: "index_stripeclub_value_rules_on_colorway_id"
    t.index ["value_id"], name: "index_stripeclub_value_rules_on_value_id"
  end

  create_table "stripeclub_values", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "pattern_id", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["pattern_id", "position"], name: "index_stripeclub_values_on_pattern_id_and_position", unique: true
    t.index ["pattern_id"], name: "index_stripeclub_values_on_pattern_id"
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
  add_foreign_key "imperfections", "patterns"
  add_foreign_key "palette_snapshots", "colorways"
  add_foreign_key "rows", "patterns"
  add_foreign_key "sequences", "patterns"
  add_foreign_key "stripeclub_colorways", "stripeclub_patterns", column: "pattern_id"
  add_foreign_key "stripeclub_imperfections", "stripeclub_patterns", column: "pattern_id"
  add_foreign_key "stripeclub_palette_snapshots", "stripeclub_colorways", column: "colorway_id"
  add_foreign_key "stripeclub_rows", "stripeclub_patterns", column: "pattern_id"
  add_foreign_key "stripeclub_sequences", "stripeclub_patterns", column: "pattern_id"
  add_foreign_key "stripeclub_stripes", "stripeclub_sequences", column: "sequence_id"
  add_foreign_key "stripeclub_stripes", "stripeclub_values", column: "value_id"
  add_foreign_key "stripeclub_value_rules", "stripeclub_colorways", column: "colorway_id"
  add_foreign_key "stripeclub_value_rules", "stripeclub_values", column: "value_id"
  add_foreign_key "stripeclub_values", "stripeclub_patterns", column: "pattern_id"
  add_foreign_key "stripes", "sequences"
  add_foreign_key "stripes", "values"
  add_foreign_key "value_rules", "colorways"
  add_foreign_key "value_rules", "values"
  add_foreign_key "values", "patterns"
end
