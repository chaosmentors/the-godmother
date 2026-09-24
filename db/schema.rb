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

ActiveRecord::Schema[8.1].define(version: 2025_12_22_184941) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "emails", force: :cascade do |t|
    t.text "body_html"
    t.text "body_plain"
    t.datetime "created_at", null: false
    t.string "direction"
    t.string "from_address", null: false
    t.string "imap_uid"
    t.string "in_reply_to"
    t.string "mailbox"
    t.string "message_id", null: false
    t.bigint "person_id"
    t.datetime "sent_at"
    t.string "subject"
    t.string "to_addresses"
    t.datetime "updated_at", null: false
    t.index ["direction"], name: "index_emails_on_direction"
    t.index ["from_address"], name: "index_emails_on_from_address"
    t.index ["mailbox", "imap_uid"], name: "index_emails_on_mailbox_and_imap_uid"
    t.index ["message_id"], name: "index_emails_on_message_id", unique: true
    t.index ["person_id"], name: "index_emails_on_person_id"
    t.index ["sent_at"], name: "index_emails_on_sent_at"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.boolean "handed_off", default: false
    t.string "label"
    t.integer "mentor_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["label"], name: "index_groups_on_label", unique: true
    t.index ["mentor_id"], name: "index_groups_on_mentor_id"
  end

  create_table "people", force: :cascade do |t|
    t.text "about"
    t.datetime "created_at", precision: nil, null: false
    t.string "email"
    t.integer "group_id"
    t.boolean "has_conference_ticket"
    t.boolean "isgodmother"
    t.string "name"
    t.string "password_digest"
    t.string "pronoun"
    t.string "random_id"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 1
    t.integer "state", default: 1
    t.datetime "ticket_reminder_sent_at"
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "validated_at"
    t.string "verification_token"
    t.index ["email"], name: "index_people_on_email", unique: true
    t.index ["random_id"], name: "index_people_on_random_id", unique: true
    t.index ["verification_token"], name: "index_people_on_verification_token", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "taggings", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.bigint "person_id"
    t.bigint "tag_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["person_id"], name: "index_taggings_on_person_id"
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", precision: nil, null: false
    t.string "name"
    t.datetime "updated_at", precision: nil, null: false
  end

  add_foreign_key "emails", "people"
  add_foreign_key "taggings", "people"
  add_foreign_key "taggings", "tags"
end
