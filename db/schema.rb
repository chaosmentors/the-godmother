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

ActiveRecord::Schema.define(version: 2020_08_16_193644) do

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "people", force: :cascade do |t|
    t.string "name"
    t.string "pronoun"
    t.string "email"
    t.text "about"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "verification_token"
    t.string "random_id"
    t.integer "role", default: 1
    t.integer "state", default: 1
    t.string "password_digest"
    t.integer "group_id"
    t.boolean "isgodmother"
    t.index ["email"], name: "index_people_on_email", unique: true
    t.index ["random_id"], name: "index_people_on_random_id", unique: true
    t.index ["verification_token"], name: "index_people_on_verification_token", unique: true
  end

  create_table "taggings", force: :cascade do |t|
    t.integer "tag_id"
    t.integer "person_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id"], name: "index_taggings_on_person_id"
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active"
  end

end
