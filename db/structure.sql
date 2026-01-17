CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "authors" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "bio" text, "status" integer DEFAULT 0 NOT NULL, "slug" varchar NOT NULL, "avatar_url" varchar, "github_url" varchar, "gitlab_url" varchar, "website_url" varchar, "bluesky_url" varchar, "ruby_social_url" varchar, "twitter_url" varchar, "linkedin_url" varchar, "youtube_url" varchar, "twitch_url" varchar, "blog_url" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_authors_on_slug" ON "authors" ("slug");
CREATE INDEX "index_authors_on_name" ON "authors" ("name");
CREATE INDEX "index_authors_on_status" ON "authors" ("status");
CREATE TABLE IF NOT EXISTS "active_storage_blobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "filename" varchar NOT NULL, "content_type" varchar, "metadata" text, "service_name" varchar NOT NULL, "byte_size" bigint NOT NULL, "checksum" varchar, "created_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_active_storage_blobs_on_key" ON "active_storage_blobs" ("key");
CREATE TABLE IF NOT EXISTS "active_storage_attachments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "record_type" varchar NOT NULL, "record_id" bigint NOT NULL, "blob_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c3b3935057"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE INDEX "index_active_storage_attachments_on_blob_id" ON "active_storage_attachments" ("blob_id");
CREATE UNIQUE INDEX "index_active_storage_attachments_uniqueness" ON "active_storage_attachments" ("record_type", "record_id", "name", "blob_id");
CREATE TABLE IF NOT EXISTS "active_storage_variant_records" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "variation_digest" varchar NOT NULL, CONSTRAINT "fk_rails_993965df05"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE UNIQUE INDEX "index_active_storage_variant_records_uniqueness" ON "active_storage_variant_records" ("blob_id", "variation_digest");
CREATE TABLE IF NOT EXISTS "categories" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "slug" varchar NOT NULL, "description" text, "icon" varchar, "display_order" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_categories_on_name" ON "categories" ("name");
CREATE UNIQUE INDEX "index_categories_on_slug" ON "categories" ("slug");
CREATE TABLE IF NOT EXISTS "ruby_gems" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "gem_name" varchar NOT NULL, "rubygems_url" varchar, "github_url" varchar, "documentation_url" varchar, "downloads_count" integer, "current_version" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "books" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "isbn" varchar, "publisher" varchar, "publication_year" integer, "page_count" integer, "format" integer, "purchase_url" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "courses" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "platform" varchar, "instructor" varchar, "duration_hours" decimal(5,2), "price_cents" integer, "currency" varchar DEFAULT 'USD', "is_free" boolean DEFAULT FALSE NOT NULL, "enrollment_url" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "tutorials" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "reading_time_minutes" integer, "publication_date" date, "author_name" varchar, "platform" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "articles" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "reading_time_minutes" integer, "publication_date" date, "author_name" varchar, "platform" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "tools" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "tool_type" varchar, "github_url" varchar, "documentation_url" varchar, "license" varchar, "is_open_source" boolean DEFAULT TRUE NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "podcasts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "host" varchar, "episode_count" integer, "frequency" varchar, "rss_feed_url" varchar, "spotify_url" varchar, "apple_podcasts_url" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "communities" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "platform" varchar NOT NULL, "join_url" varchar NOT NULL, "member_count" integer, "is_official" boolean DEFAULT FALSE NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "action_text_rich_texts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "body" text, "record_type" varchar NOT NULL, "record_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_action_text_rich_texts_uniqueness" ON "action_text_rich_texts" ("record_type", "record_id", "name");
CREATE UNIQUE INDEX "index_ruby_gems_on_gem_name" ON "ruby_gems" ("gem_name");
CREATE TABLE IF NOT EXISTS "categories_entries" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "category_id" integer NOT NULL, "entry_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "is_primary" boolean DEFAULT FALSE NOT NULL, "is_featured" boolean DEFAULT FALSE NOT NULL, CONSTRAINT "fk_rails_11da8fc9a6"
FOREIGN KEY ("entry_id")
  REFERENCES "entries" ("id")
 ON DELETE CASCADE, CONSTRAINT "fk_rails_a608a4a5b5"
FOREIGN KEY ("category_id")
  REFERENCES "categories" ("id")
 ON DELETE CASCADE);
CREATE INDEX "index_categories_entries_on_category_id" ON "categories_entries" ("category_id");
CREATE INDEX "index_categories_entries_on_entry_id" ON "categories_entries" ("entry_id");
CREATE UNIQUE INDEX "index_categories_entries_on_category_id_and_entry_id" ON "categories_entries" ("category_id", "entry_id");
CREATE TABLE IF NOT EXISTS "entries_authors" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "author_id" integer NOT NULL, "entry_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_8938836c7a"
FOREIGN KEY ("entry_id")
  REFERENCES "entries" ("id")
 ON DELETE CASCADE, CONSTRAINT "fk_rails_ef4dd6bddc"
FOREIGN KEY ("author_id")
  REFERENCES "authors" ("id")
 ON DELETE CASCADE);
CREATE INDEX "index_entries_authors_on_author_id" ON "entries_authors" ("author_id");
CREATE INDEX "index_entries_authors_on_entry_id" ON "entries_authors" ("entry_id");
CREATE UNIQUE INDEX "index_entries_authors_on_author_id_and_entry_id" ON "entries_authors" ("author_id", "entry_id");
CREATE VIRTUAL TABLE entries_fts USING fts5(
            entry_id UNINDEXED,
            title,
            description,
            tags,
            tokenize='porter ascii'
          )
/* entries_fts(entry_id,title,description,tags) */;
CREATE VIRTUAL TABLE authors_fts USING fts5(
            author_id UNINDEXED,
            name,
            tokenize='porter ascii'
          )
/* authors_fts(author_id,name) */;
CREATE UNIQUE INDEX "index_categories_entries_on_entry_id_primary" ON "categories_entries" ("entry_id") WHERE is_primary = 1;
CREATE TABLE IF NOT EXISTS "active_hashcash_stamps" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "version" varchar NOT NULL, "bits" integer NOT NULL, "date" date NOT NULL, "resource" varchar NOT NULL, "ext" varchar NOT NULL, "rand" varchar NOT NULL, "counter" varchar NOT NULL, "request_path" varchar, "ip_address" varchar, "context" json, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE INDEX "index_active_hashcash_stamps_on_ip_address_and_created_at" ON "active_hashcash_stamps" ("ip_address", "created_at") WHERE ip_address IS NOT NULL;
CREATE UNIQUE INDEX "index_active_hashcash_stamps_unique" ON "active_hashcash_stamps" ("counter", "rand", "date", "resource", "bits", "version", "ext");
CREATE TABLE IF NOT EXISTS "entries" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "title" varchar, "description" text, "url" varchar, "status" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "image_url" varchar, "experience_level" integer, "published" boolean DEFAULT FALSE NOT NULL, "tags" text, "slug" varchar, "entryable_type" varchar, "entryable_id" integer, "submitter_name" varchar, "submitter_email" varchar, "featured_at" datetime(6));
CREATE INDEX "index_entries_on_experience_level" ON "entries" ("experience_level");
CREATE INDEX "index_entries_on_published" ON "entries" ("published");
CREATE INDEX "index_entries_on_status" ON "entries" ("status");
CREATE UNIQUE INDEX "index_entries_on_slug" ON "entries" ("slug");
CREATE INDEX "index_entries_on_title" ON "entries" ("title");
CREATE INDEX "index_entries_on_entryable_type_and_entryable_id" ON "entries" ("entryable_type", "entryable_id");
CREATE TABLE IF NOT EXISTS "entry_reviews" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "entry_id" integer NOT NULL, "status" integer DEFAULT 0 NOT NULL, "comment" text, "reviewer_id" integer, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_5fc89ca42d"
FOREIGN KEY ("entry_id")
  REFERENCES "entries" ("id")
);
CREATE INDEX "index_entry_reviews_on_entry_id" ON "entry_reviews" ("entry_id");
CREATE INDEX "index_entry_reviews_on_status" ON "entry_reviews" ("status");
CREATE TABLE IF NOT EXISTS "newsletters" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar);
CREATE TABLE IF NOT EXISTS "blogs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar);
CREATE TABLE IF NOT EXISTS "videos" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar);
CREATE TABLE IF NOT EXISTS "channels" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar);
CREATE TABLE IF NOT EXISTS "documentations" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar);
CREATE TABLE IF NOT EXISTS "testing_resources" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar);
CREATE TABLE IF NOT EXISTS "development_environments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar);
CREATE TABLE IF NOT EXISTS "jobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar);
CREATE TABLE IF NOT EXISTS "frameworks" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar);
CREATE TABLE IF NOT EXISTS "directories" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar);
CREATE TABLE IF NOT EXISTS "products" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar);
CREATE TABLE IF NOT EXISTS "author_proposals" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "author_id" integer, "matched_entry_id" integer, "resource_url" text, "original_resource_url" text, "link_updates" text, "bio_text" text, "description_text" text, "author_name" varchar, "submitter_name" varchar, "submitter_email" varchar NOT NULL, "submission_notes" text, "status" integer DEFAULT 0 NOT NULL, "reviewer_id" integer, "admin_comment" text, "reviewed_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_726c9725d7"
FOREIGN KEY ("author_id")
  REFERENCES "authors" ("id")
 ON DELETE CASCADE, CONSTRAINT "fk_rails_5d96ad48b6"
FOREIGN KEY ("matched_entry_id")
  REFERENCES "entries" ("id")
 ON DELETE SET NULL);
CREATE INDEX "index_author_proposals_on_author_id" ON "author_proposals" ("author_id");
CREATE INDEX "index_author_proposals_on_matched_entry_id" ON "author_proposals" ("matched_entry_id");
CREATE INDEX "index_author_proposals_on_status" ON "author_proposals" ("status");
CREATE INDEX "index_author_proposals_on_submitter_email" ON "author_proposals" ("submitter_email");
CREATE INDEX "index_author_proposals_on_created_at" ON "author_proposals" ("created_at");
CREATE TABLE IF NOT EXISTS "sessions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "token" varchar NOT NULL, "ip_address" varchar, "user_agent" varchar, "last_active_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_758836b4f0"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
 ON DELETE CASCADE);
CREATE INDEX "index_sessions_on_user_id" ON "sessions" ("user_id");
CREATE UNIQUE INDEX "index_sessions_on_token" ON "sessions" ("token");
CREATE INDEX "index_sessions_on_last_active_at" ON "sessions" ("last_active_at");
CREATE TABLE IF NOT EXISTS "bans" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer, "ip_address" varchar, "reason" text, "expires_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_070022cd76"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
 ON DELETE CASCADE);
CREATE INDEX "index_bans_on_user_id" ON "bans" ("user_id");
CREATE INDEX "index_bans_on_ip_address" ON "bans" ("ip_address");
CREATE INDEX "index_bans_on_expires_at" ON "bans" ("expires_at");
CREATE TABLE IF NOT EXISTS "users" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "email_address" varchar NOT NULL, "password_digest" varchar NOT NULL, "name" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "role" varchar DEFAULT 'editor' NOT NULL, "status" varchar DEFAULT 'active' NOT NULL);
CREATE UNIQUE INDEX "index_users_on_email_address" ON "users" ("email_address");
