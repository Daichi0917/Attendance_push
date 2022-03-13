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

ActiveRecord::Schema.define(version: 20200408113114) do

  create_table "approvals", force: :cascade do |t|
    t.integer "superior_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "month_at"
    t.boolean "approval_flag", default: false, null: false
    t.integer "user_id"
    t.integer "confirm", default: 0, null: false
    t.index ["user_id"], name: "index_approvals_on_user_id"
  end

  create_table "attendances", force: :cascade do |t|
    t.date "worked_on"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "note"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "tommorow_index", default: false, null: false
    t.string "overtime_memo"
    t.string "name"
    t.datetime "endtime_at"
    t.boolean "overtime_check", default: false, null: false
    t.boolean "attendance_change_check", default: false, null: false
    t.boolean "attendance_change_flag", default: false, null: false
    t.integer "suppoter"
    t.integer "confirm", default: 0, null: false
    t.integer "overtime_confirm", default: 0, null: false
    t.integer "approval_id"
    t.datetime "updated_started_at"
    t.datetime "updated_finished_at"
    t.datetime "before_started_at"
    t.datetime "before_finished_at"
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "bases", force: :cascade do |t|
    t.integer "base_number"
    t.string "base_name"
    t.string "base_attendance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "admin", default: false
    t.string "affiliation"
    t.datetime "basic_time", default: "2022-02-22 23:00:00"
    t.datetime "work_time", default: "2022-02-22 22:30:00"
    t.boolean "superior", default: false
    t.integer "employee_number"
    t.string "uid"
    t.datetime "designated_work_start_time", default: "2022-02-23 00:00:00"
    t.datetime "designated_work_end_time", default: "2022-02-23 09:00:00"
    t.datetime "basic_work_time", default: "2022-02-22 23:00:00"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
