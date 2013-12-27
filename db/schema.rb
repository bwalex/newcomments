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

ActiveRecord::Schema.define(version: 20131123204539) do

  create_table "articles", force: true do |t|
    t.integer  "site_id"
    t.string   "name"
    t.string   "identifier"
    t.string   "url"
    t.boolean  "closed",     default: false
    t.boolean  "hidden",     default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "articles", ["site_id", "identifier"], name: "index_articles_on_site_id_and_identifier", unique: true, using: :btree

  create_table "comments", force: true do |t|
    t.integer  "article_id"
    t.string   "ip"
    t.string   "name"
    t.string   "email"
    t.string   "hashed_email"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["article_id"], name: "comments_article_id_fk", using: :btree

  create_table "site_users", force: true do |t|
    t.integer  "user_id"
    t.integer  "site_id"
    t.integer  "access_level"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "site_users", ["site_id", "user_id"], name: "index_site_users_on_site_id_and_user_id", unique: true, using: :btree
  add_index "site_users", ["user_id"], name: "site_users_user_id_fk", using: :btree

  create_table "sites", force: true do |t|
    t.string   "domain"
    t.boolean  "closed",     default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sites", ["domain"], name: "index_sites_on_domain", unique: true, using: :btree

  create_table "subscriptions", force: true do |t|
    t.integer  "user_id"
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subscriptions", ["site_id", "user_id"], name: "index_subscriptions_on_site_id_and_user_id", unique: true, using: :btree
  add_index "subscriptions", ["user_id"], name: "subscriptions_user_id_fk", using: :btree

  create_table "users", force: true do |t|
    t.string   "email"
    t.string   "password"
    t.string   "salt"
    t.boolean  "admin"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

  add_foreign_key "articles", "sites", name: "articles_site_id_fk", dependent: :delete

  add_foreign_key "comments", "articles", name: "comments_article_id_fk", dependent: :delete

  add_foreign_key "site_users", "sites", name: "site_users_site_id_fk", dependent: :delete
  add_foreign_key "site_users", "users", name: "site_users_user_id_fk", dependent: :delete

  add_foreign_key "subscriptions", "sites", name: "subscriptions_site_id_fk", dependent: :delete
  add_foreign_key "subscriptions", "users", name: "subscriptions_user_id_fk", dependent: :delete

end
