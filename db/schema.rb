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

ActiveRecord::Schema[8.1].define(version: 2026_10_14_100005) do
  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_companies_on_name", unique: true
  end

  create_table "locker_events", force: :cascade do |t|
    t.integer "locker_id", null: false
    t.integer "user_id", null: false
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_locker_events_on_created_at"
    t.index ["locker_id"], name: "index_locker_events_on_locker_id"
    t.index ["user_id"], name: "index_locker_events_on_user_id"
  end

  create_table "lockers", force: :cascade do |t|
    t.string "name", null: false
    t.string "state", default: "closed", null: false
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_lockers_on_name", unique: true
    t.index ["team_id"], name: "index_lockers_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.integer "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_teams_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_teams_on_company_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "role", default: "employee", null: false
    t.integer "team_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "locker_events", "lockers"
  add_foreign_key "locker_events", "users"
  add_foreign_key "lockers", "teams"
  add_foreign_key "teams", "companies"
  add_foreign_key "users", "teams"
end
