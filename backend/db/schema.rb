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

ActiveRecord::Schema[7.2].define(version: 2026_09_15_131520) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "auto_approve_limit", precision: 10, scale: 2, default: "0.0", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "expense_histories", force: :cascade do |t|
    t.bigint "expense_id", null: false
    t.string "from_status"
    t.string "to_status", null: false
    t.bigint "actor_user_id"
    t.string "comment"
    t.datetime "created_at", null: false
    t.index ["actor_user_id"], name: "index_expense_histories_on_actor_user_id"
    t.index ["expense_id"], name: "index_expense_histories_on_expense_id"
    t.check_constraint "to_status::text <> 'rejected'::text OR comment IS NOT NULL AND comment::text <> ''::text", name: "check_rejection_requires_comment"
  end

  create_table "expenses", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "category_id", null: false
    t.bigint "user_id", null: false
    t.date "spent_on", null: false
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_expenses_on_category_id"
    t.index ["spent_on"], name: "index_expenses_on_spent_on"
    t.index ["status"], name: "index_expenses_on_status"
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "message", null: false
    t.boolean "read", default: false, null: false
    t.bigint "expense_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_id"], name: "index_notifications_on_expense_id"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "manager_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["manager_id"], name: "index_teams_on_manager_id"
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "employee", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "team_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "expense_histories", "expenses"
  add_foreign_key "expense_histories", "users", column: "actor_user_id"
  add_foreign_key "expenses", "categories"
  add_foreign_key "expenses", "users"
  add_foreign_key "notifications", "expenses"
  add_foreign_key "notifications", "users"
  add_foreign_key "teams", "users", column: "manager_id"
  add_foreign_key "users", "teams"
end
