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

ActiveRecord::Schema[8.1].define(version: 2026_10_10_005537) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "outbox_events", force: :cascade do |t|
    t.string "subject", null: false
    t.bigint "entity_id", null: false
    t.jsonb "payload", null: false
    t.datetime "occurred_at", null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.index ["id"], name: "index_outbox_events_unpublished", where: "(published_at IS NULL)"
    t.index ["published_at"], name: "index_outbox_events_on_published_at", where: "(published_at IS NOT NULL)"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "title", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.bigint "user_id", null: false
    t.bigint "order_id"
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "available", null: false
    t.check_constraint "(status::text = ANY (ARRAY['reserved'::character varying::text, 'sold'::character varying::text])) = (order_id IS NOT NULL)", name: "tickets_order_id_matches_status"
    t.check_constraint "status::text = ANY (ARRAY['available'::character varying::text, 'reserved'::character varying::text, 'sold'::character varying::text, 'cancelled'::character varying::text])", name: "tickets_status_known"
  end
end
