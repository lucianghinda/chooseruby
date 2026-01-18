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

ActiveRecord::Schema[8.2].define(version: 2026_01_11_063409) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_hashcash_stamps", force: :cascade do |t|
    t.integer "bits", null: false
    t.json "context"
    t.string "counter", null: false
    t.datetime "created_at", precision: nil, null: false
    t.date "date", null: false
    t.string "ext", null: false
    t.string "ip_address"
    t.string "rand", null: false
    t.string "request_path"
    t.string "resource", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "version", null: false
    t.index ["counter", "rand", "date", "resource", "bits", "version", "ext"], name: "index_active_hashcash_stamps_unique", unique: true
    t.index ["ip_address", "created_at"], name: "index_active_hashcash_stamps_on_ip_address_and_created_at", where: "ip_address IS NOT NULL"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.string "author_name"
    t.datetime "created_at", null: false
    t.string "platform"
    t.date "publication_date"
    t.integer "reading_time_minutes"
    t.datetime "updated_at", null: false
  end

  create_table "author_proposals", force: :cascade do |t|
    t.text "admin_comment"
    t.integer "author_id"
    t.string "author_name"
    t.text "bio_text"
    t.datetime "created_at", null: false
    t.text "description_text"
    t.text "link_updates"
    t.integer "matched_entry_id"
    t.text "original_resource_url"
    t.text "resource_url"
    t.datetime "reviewed_at"
    t.integer "reviewer_id"
    t.integer "status", default: 0, null: false
    t.text "submission_notes"
    t.string "submitter_email", null: false
    t.string "submitter_name"
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_author_proposals_on_author_id"
    t.index ["created_at"], name: "index_author_proposals_on_created_at"
    t.index ["matched_entry_id"], name: "index_author_proposals_on_matched_entry_id"
    t.index ["status"], name: "index_author_proposals_on_status"
    t.index ["submitter_email"], name: "index_author_proposals_on_submitter_email"
  end

  create_table "authors", force: :cascade do |t|
    t.string "avatar_url"
    t.text "bio"
    t.string "blog_url"
    t.string "bluesky_url"
    t.datetime "created_at", null: false
    t.string "github_url"
    t.string "gitlab_url"
    t.string "linkedin_url"
    t.string "name", null: false
    t.string "ruby_social_url"
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.string "twitch_url"
    t.string "twitter_url"
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.string "youtube_url"
    t.index ["name"], name: "index_authors_on_name"
    t.index ["slug"], name: "index_authors_on_slug", unique: true
    t.index ["status"], name: "index_authors_on_status"
  end

  create_table "bans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "ip_address"
    t.text "reason"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["expires_at"], name: "index_bans_on_expires_at"
    t.index ["ip_address"], name: "index_bans_on_ip_address"
    t.index ["user_id"], name: "index_bans_on_user_id"
  end

  create_table "blogs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "books", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "format"
    t.string "isbn"
    t.integer "page_count"
    t.integer "publication_year"
    t.string "publisher"
    t.string "purchase_url"
    t.datetime "updated_at", null: false
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "display_order", default: 0, null: false
    t.string "icon"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "categories_entries", force: :cascade do |t|
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.integer "entry_id", null: false
    t.boolean "is_featured", default: false, null: false
    t.boolean "is_primary", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "entry_id"], name: "index_categories_entries_on_category_id_and_entry_id", unique: true
    t.index ["category_id"], name: "index_categories_entries_on_category_id"
    t.index ["entry_id"], name: "index_categories_entries_on_entry_id"
    t.index ["entry_id"], name: "index_categories_entries_on_entry_id_primary", unique: true, where: "is_primary = 1"
  end

  create_table "channels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "communities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_official", default: false, null: false
    t.string "join_url", null: false
    t.integer "member_count"
    t.string "platform", null: false
    t.datetime "updated_at", null: false
  end

  create_table "courses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "USD"
    t.decimal "duration_hours", precision: 5, scale: 2
    t.string "enrollment_url"
    t.string "instructor"
    t.boolean "is_free", default: false, null: false
    t.string "platform"
    t.integer "price_cents"
    t.datetime "updated_at", null: false
  end

  create_table "development_environments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "directories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "documentations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "entryable_id"
    t.string "entryable_type"
    t.integer "experience_level"
    t.datetime "featured_at"
    t.string "image_url"
    t.boolean "published", default: false, null: false
    t.string "slug"
    t.integer "status", default: 0, null: false
    t.string "submitter_email"
    t.string "submitter_name"
    t.text "tags"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["entryable_type", "entryable_id"], name: "index_entries_on_entryable_type_and_entryable_id"
    t.index ["experience_level"], name: "index_entries_on_experience_level"
    t.index ["published"], name: "index_entries_on_published"
    t.index ["slug"], name: "index_entries_on_slug", unique: true
    t.index ["status"], name: "index_entries_on_status"
    t.index ["title"], name: "index_entries_on_title"
  end

  create_table "entries_authors", force: :cascade do |t|
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.integer "entry_id", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id", "entry_id"], name: "index_entries_authors_on_author_id_and_entry_id", unique: true
    t.index ["author_id"], name: "index_entries_authors_on_author_id"
    t.index ["entry_id"], name: "index_entries_authors_on_entry_id"
  end

  create_table "entry_reviews", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "entry_id", null: false
    t.integer "reviewer_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id"], name: "index_entry_reviews_on_entry_id"
    t.index ["status"], name: "index_entry_reviews_on_status"
  end

  create_table "frameworks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "jobs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "newsletters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "podcasts", force: :cascade do |t|
    t.string "apple_podcasts_url"
    t.datetime "created_at", null: false
    t.integer "episode_count"
    t.string "frequency"
    t.string "host"
    t.string "rss_feed_url"
    t.string "spotify_url"
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "ruby_gems", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "current_version"
    t.string "documentation_url"
    t.integer "downloads_count"
    t.string "gem_name", null: false
    t.string "github_url"
    t.string "rubygems_url"
    t.datetime "updated_at", null: false
    t.index ["gem_name"], name: "index_ruby_gems_on_gem_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "last_active_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["last_active_at"], name: "index_sessions_on_last_active_at"
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "testing_resources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "tools", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "documentation_url"
    t.string "github_url"
    t.boolean "is_open_source", default: true, null: false
    t.string "license"
    t.string "tool_type"
    t.datetime "updated_at", null: false
  end

  create_table "tutorials", force: :cascade do |t|
    t.string "author_name"
    t.datetime "created_at", null: false
    t.string "platform"
    t.date "publication_date"
    t.integer "reading_time_minutes"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role", default: "editor", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "videos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "author_proposals", "authors", on_delete: :cascade
  add_foreign_key "author_proposals", "entries", column: "matched_entry_id", on_delete: :nullify
  add_foreign_key "bans", "users", on_delete: :cascade
  add_foreign_key "categories_entries", "categories", on_delete: :cascade
  add_foreign_key "categories_entries", "entries", on_delete: :cascade
  add_foreign_key "entries_authors", "authors", on_delete: :cascade
  add_foreign_key "entries_authors", "entries", on_delete: :cascade
  add_foreign_key "entry_reviews", "entries"
  add_foreign_key "sessions", "users", on_delete: :cascade
end
