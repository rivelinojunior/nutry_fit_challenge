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

ActiveRecord::Schema[8.1].define(version: 2026_05_08_173724) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "challenge_tasks", force: :cascade do |t|
    t.time "allowed_end_time"
    t.time "allowed_start_time"
    t.bigint "challenge_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "links"
    t.string "name"
    t.integer "points"
    t.date "scheduled_on"
    t.datetime "updated_at", null: false
    t.index ["challenge_id", "scheduled_on"], name: "index_challenge_tasks_on_challenge_id_and_scheduled_on"
    t.index ["challenge_id"], name: "index_challenge_tasks_on_challenge_id"
  end

  create_table "challenges", force: :cascade do |t|
    t.string "challenge_code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "end_date"
    t.string "name"
    t.date "start_date"
    t.string "status", default: "draft", null: false
    t.string "timezone", default: "America/Sao_Paulo", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["challenge_code"], name: "index_challenges_on_challenge_code", unique: true
    t.index ["user_id"], name: "index_challenges_on_user_id"
  end

  create_table "checkins", force: :cascade do |t|
    t.bigint "challenge_task_id", null: false
    t.datetime "checked_at"
    t.datetime "created_at", null: false
    t.bigint "participant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_task_id"], name: "index_checkins_on_challenge_task_id"
    t.index ["participant_id", "challenge_task_id"], name: "index_checkins_on_participant_id_and_challenge_task_id", unique: true
    t.index ["participant_id"], name: "index_checkins_on_participant_id"
  end

  create_table "participants", force: :cascade do |t|
    t.bigint "challenge_id", null: false
    t.datetime "created_at", null: false
    t.datetime "joined_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["challenge_id"], name: "index_participants_on_challenge_id"
    t.index ["user_id", "challenge_id"], name: "index_participants_on_user_id_and_challenge_id", unique: true
    t.index ["user_id"], name: "index_participants_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "user"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "challenge_tasks", "challenges"
  add_foreign_key "challenges", "users"
  add_foreign_key "checkins", "challenge_tasks"
  add_foreign_key "checkins", "participants"
  add_foreign_key "participants", "challenges"
  add_foreign_key "participants", "users"
end
