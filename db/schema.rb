# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_09_21_222209) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cohort_comparisons", force: :cascade do |t|
    t.bigint "cohort_a_id"
    t.bigint "timespan_a_id"
    t.bigint "cohort_b_id"
    t.bigint "timespan_b_id"
    t.json "results"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cohort_a_id", "timespan_a_id", "cohort_b_id", "timespan_b_id"], name: "by_cohort_and_timespan", unique: true
    t.index ["cohort_a_id"], name: "index_cohort_comparisons_on_cohort_a_id"
    t.index ["cohort_b_id"], name: "index_cohort_comparisons_on_cohort_b_id"
    t.index ["timespan_a_id"], name: "index_cohort_comparisons_on_timespan_a_id"
    t.index ["timespan_b_id"], name: "index_cohort_comparisons_on_timespan_b_id"
  end

  create_table "cohort_summaries", force: :cascade do |t|
    t.bigint "cohort_id"
    t.bigint "timespan_id"
    t.json "results"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cohort_id", "timespan_id"], name: "index_cohort_summaries_on_cohort_id_and_timespan_id", unique: true
    t.index ["cohort_id"], name: "index_cohort_summaries_on_cohort_id"
    t.index ["timespan_id"], name: "index_cohort_summaries_on_timespan_id"
  end

  create_table "cohorts", force: :cascade do |t|
    t.text "twitter_ids", default: [], array: true
    t.text "description"
    t.string "index_prefix"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "name"
  end

  create_table "timespans", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "start", null: false
    t.datetime "end", null: false
    t.integer "in_seconds", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "whitelisted_jwts", force: :cascade do |t|
    t.string "jti", null: false
    t.string "aud"
    t.datetime "exp", null: false
    t.bigint "user_id", null: false
    t.index ["jti"], name: "index_whitelisted_jwts_on_jti", unique: true
    t.index ["user_id"], name: "index_whitelisted_jwts_on_user_id"
  end

  add_foreign_key "cohort_comparisons", "cohorts", column: "cohort_a_id"
  add_foreign_key "cohort_comparisons", "cohorts", column: "cohort_b_id"
  add_foreign_key "cohort_comparisons", "timespans", column: "timespan_a_id"
  add_foreign_key "cohort_comparisons", "timespans", column: "timespan_b_id"
  add_foreign_key "cohort_summaries", "cohorts"
  add_foreign_key "cohort_summaries", "timespans"
  add_foreign_key "whitelisted_jwts", "users", on_delete: :cascade
end
