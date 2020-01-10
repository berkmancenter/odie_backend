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

ActiveRecord::Schema.define(version: 2020_01_10_171211) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "plpgsql"

  create_table "cohorts", force: :cascade do |t|
    t.text "twitter_ids", default: [], array: true
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "data_configs", force: :cascade do |t|
    t.string "index_name"
    t.string "keywords", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "data_configs_media_sources", id: false, force: :cascade do |t|
    t.bigint "data_config_id", null: false
    t.bigint "media_source_id", null: false
  end

  create_table "data_sets", force: :cascade do |t|
    t.string "index_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "data_config_id"
    t.integer "num_users"
    t.integer "num_tweets"
    t.integer "num_retweets"
    t.hstore "hashtags", default: {}
    t.hstore "top_words", default: {}
    t.hstore "top_urls", default: {}
    t.hstore "top_mentions", default: {}
    t.hstore "top_sources", default: {}
    t.hstore "top_retweets", default: {}
    t.bigint "cohort_id"
    t.index ["cohort_id"], name: "index_data_sets_on_cohort_id"
    t.index ["data_config_id"], name: "index_data_sets_on_data_config_id"
  end

  create_table "media_sources", force: :cascade do |t|
    t.boolean "active"
    t.text "description"
    t.string "keyword"
    t.string "name"
    t.string "url"
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

  add_foreign_key "data_sets", "cohorts"
  add_foreign_key "data_sets", "data_configs"
end
