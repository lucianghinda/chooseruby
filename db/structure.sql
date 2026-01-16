CREATE TABLE IF NOT EXISTS "action_text_rich_texts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "body" text, "created_at" datetime(6) NOT NULL, "name" varchar NOT NULL, "record_id" bigint NOT NULL, "record_type" varchar NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_action_text_rich_texts_uniqueness" ON "action_text_rich_texts" ("record_type", "record_id", "name") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "active_storage_blobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "byte_size" bigint NOT NULL, "checksum" varchar, "content_type" varchar, "created_at" datetime(6) NOT NULL, "filename" varchar NOT NULL, "key" varchar NOT NULL, "metadata" text, "service_name" varchar NOT NULL);
CREATE UNIQUE INDEX "index_active_storage_blobs_on_key" ON "active_storage_blobs" ("key") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "articles" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "author_name" varchar, "created_at" datetime(6) NOT NULL, "platform" varchar, "publication_date" date, "reading_time_minutes" integer, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "authors" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "avatar_url" varchar, "bio" text, "blog_url" varchar, "bluesky_url" varchar, "created_at" datetime(6) NOT NULL, "github_url" varchar, "gitlab_url" varchar, "linkedin_url" varchar, "name" varchar NOT NULL, "ruby_social_url" varchar, "slug" varchar NOT NULL, "status" integer DEFAULT 0 NOT NULL, "twitch_url" varchar, "twitter_url" varchar, "updated_at" datetime(6) NOT NULL, "website_url" varchar, "youtube_url" varchar);
CREATE INDEX "index_authors_on_name" ON "authors" ("name") /*application='Chooseruby'*/;
CREATE UNIQUE INDEX "index_authors_on_slug" ON "authors" ("slug") /*application='Chooseruby'*/;
CREATE INDEX "index_authors_on_status" ON "authors" ("status") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "books" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "format" integer, "isbn" varchar, "page_count" integer, "publication_year" integer, "publisher" varchar, "purchase_url" varchar, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "categories" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "description" text, "display_order" integer DEFAULT 0 NOT NULL, "icon" varchar, "name" varchar NOT NULL, "slug" varchar NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_categories_on_name" ON "categories" ("name") /*application='Chooseruby'*/;
CREATE UNIQUE INDEX "index_categories_on_slug" ON "categories" ("slug") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "communities" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "is_official" boolean DEFAULT FALSE NOT NULL, "join_url" varchar NOT NULL, "member_count" integer, "platform" varchar NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "courses" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "currency" varchar DEFAULT 'USD', "duration_hours" decimal(5,2), "enrollment_url" varchar, "instructor" varchar, "is_free" boolean DEFAULT FALSE NOT NULL, "platform" varchar, "price_cents" integer, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "podcasts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "apple_podcasts_url" varchar, "created_at" datetime(6) NOT NULL, "episode_count" integer, "frequency" varchar, "host" varchar, "rss_feed_url" varchar, "spotify_url" varchar, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "ruby_gems" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "current_version" varchar, "documentation_url" varchar, "downloads_count" integer, "gem_name" varchar NOT NULL, "github_url" varchar, "rubygems_url" varchar, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_ruby_gems_on_gem_name" ON "ruby_gems" ("gem_name") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "tools" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "documentation_url" varchar, "github_url" varchar, "is_open_source" boolean DEFAULT TRUE NOT NULL, "license" varchar, "tool_type" varchar, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "tutorials" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "author_name" varchar, "created_at" datetime(6) NOT NULL, "platform" varchar, "publication_date" date, "reading_time_minutes" integer, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "active_storage_attachments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, "name" varchar NOT NULL, "record_id" bigint NOT NULL, "record_type" varchar NOT NULL, CONSTRAINT "fk_rails_c3b3935057"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE INDEX "index_active_storage_attachments_on_blob_id" ON "active_storage_attachments" ("blob_id") /*application='Chooseruby'*/;
CREATE UNIQUE INDEX "index_active_storage_attachments_uniqueness" ON "active_storage_attachments" ("record_type", "record_id", "name", "blob_id") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "active_storage_variant_records" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "variation_digest" varchar NOT NULL, CONSTRAINT "fk_rails_993965df05"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE UNIQUE INDEX "index_active_storage_variant_records_uniqueness" ON "active_storage_variant_records" ("blob_id", "variation_digest") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "categories_entries" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "category_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "entry_id" integer NOT NULL, "updated_at" datetime(6) NOT NULL, "is_primary" boolean DEFAULT FALSE NOT NULL /*application='Chooseruby'*/, "is_featured" boolean DEFAULT FALSE NOT NULL /*application='Chooseruby'*/, CONSTRAINT "fk_rails_a608a4a5b5"
FOREIGN KEY ("category_id")
  REFERENCES "categories" ("id")
 ON DELETE CASCADE, CONSTRAINT "fk_rails_11da8fc9a6"
FOREIGN KEY ("entry_id")
  REFERENCES "entries" ("id")
 ON DELETE CASCADE);
CREATE UNIQUE INDEX "index_categories_entries_on_category_id_and_entry_id" ON "categories_entries" ("category_id", "entry_id") /*application='Chooseruby'*/;
CREATE INDEX "index_categories_entries_on_category_id" ON "categories_entries" ("category_id") /*application='Chooseruby'*/;
CREATE INDEX "index_categories_entries_on_entry_id" ON "categories_entries" ("entry_id") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "entries_authors" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "author_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "entry_id" integer NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_ef4dd6bddc"
FOREIGN KEY ("author_id")
  REFERENCES "authors" ("id")
 ON DELETE CASCADE, CONSTRAINT "fk_rails_8938836c7a"
FOREIGN KEY ("entry_id")
  REFERENCES "entries" ("id")
 ON DELETE CASCADE);
CREATE UNIQUE INDEX "index_entries_authors_on_author_id_and_entry_id" ON "entries_authors" ("author_id", "entry_id") /*application='Chooseruby'*/;
CREATE INDEX "index_entries_authors_on_author_id" ON "entries_authors" ("author_id") /*application='Chooseruby'*/;
CREATE INDEX "index_entries_authors_on_entry_id" ON "entries_authors" ("entry_id") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE VIRTUAL TABLE entries_fts USING fts5(
            entry_id UNINDEXED,
            title,
            description,
            tags,
            tokenize='porter ascii'
          )
/* entries_fts(entry_id,title,description,tags) */;
CREATE TABLE IF NOT EXISTS 'entries_fts_data'(id INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE IF NOT EXISTS 'entries_fts_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'entries_fts_content'(id INTEGER PRIMARY KEY, c0, c1, c2, c3);
CREATE TABLE IF NOT EXISTS 'entries_fts_docsize'(id INTEGER PRIMARY KEY, sz BLOB);
CREATE TABLE IF NOT EXISTS 'entries_fts_config'(k PRIMARY KEY, v) WITHOUT ROWID;
CREATE VIRTUAL TABLE authors_fts USING fts5(
            author_id UNINDEXED,
            name,
            tokenize='porter ascii'
          )
/* authors_fts(author_id,name) */;
CREATE TABLE IF NOT EXISTS 'authors_fts_data'(id INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE IF NOT EXISTS 'authors_fts_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'authors_fts_content'(id INTEGER PRIMARY KEY, c0, c1);
CREATE TABLE IF NOT EXISTS 'authors_fts_docsize'(id INTEGER PRIMARY KEY, sz BLOB);
CREATE TABLE IF NOT EXISTS 'authors_fts_config'(k PRIMARY KEY, v) WITHOUT ROWID;
CREATE UNIQUE INDEX "index_categories_entries_on_entry_id_primary" ON "categories_entries" ("entry_id") WHERE is_primary = 1 /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "active_hashcash_stamps" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "version" varchar NOT NULL, "bits" integer NOT NULL, "date" date NOT NULL, "resource" varchar NOT NULL, "ext" varchar NOT NULL, "rand" varchar NOT NULL, "counter" varchar NOT NULL, "request_path" varchar, "ip_address" varchar, "context" json, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE INDEX "index_active_hashcash_stamps_on_ip_address_and_created_at" ON "active_hashcash_stamps" ("ip_address", "created_at") WHERE ip_address IS NOT NULL /*application='Chooseruby'*/;
CREATE UNIQUE INDEX "index_active_hashcash_stamps_unique" ON "active_hashcash_stamps" ("counter", "rand", "date", "resource", "bits", "version", "ext") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "entries" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "description" text, "entryable_id" integer, "entryable_type" varchar, "experience_level" integer, "image_url" varchar, "published" boolean DEFAULT FALSE NOT NULL, "slug" varchar, "status" integer DEFAULT 0 NOT NULL, "tags" text, "title" varchar, "updated_at" datetime(6) NOT NULL, "url" varchar, "submitter_name" varchar, "submitter_email" varchar, "featured_at" datetime(6) /*application='Chooseruby'*/);
CREATE INDEX "index_entries_on_entryable_type_and_entryable_id" ON "entries" ("entryable_type", "entryable_id") /*application='Chooseruby'*/;
CREATE INDEX "index_entries_on_experience_level" ON "entries" ("experience_level") /*application='Chooseruby'*/;
CREATE INDEX "index_entries_on_published" ON "entries" ("published") /*application='Chooseruby'*/;
CREATE UNIQUE INDEX "index_entries_on_slug" ON "entries" ("slug") /*application='Chooseruby'*/;
CREATE INDEX "index_entries_on_status" ON "entries" ("status") /*application='Chooseruby'*/;
CREATE INDEX "index_entries_on_title" ON "entries" ("title") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "entry_reviews" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "entry_id" integer NOT NULL, "status" integer DEFAULT 0 NOT NULL, "comment" text, "reviewer_id" integer, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_5fc89ca42d"
FOREIGN KEY ("entry_id")
  REFERENCES "entries" ("id")
);
CREATE INDEX "index_entry_reviews_on_entry_id" ON "entry_reviews" ("entry_id") /*application='Chooseruby'*/;
CREATE INDEX "index_entry_reviews_on_status" ON "entry_reviews" ("status") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "newsletters" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar /*application='Chooseruby'*/);
CREATE TABLE IF NOT EXISTS "blogs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar /*application='Chooseruby'*/);
CREATE TABLE IF NOT EXISTS "videos" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar /*application='Chooseruby'*/);
CREATE TABLE IF NOT EXISTS "channels" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar /*application='Chooseruby'*/);
CREATE TABLE IF NOT EXISTS "documentations" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar /*application='Chooseruby'*/);
CREATE TABLE IF NOT EXISTS "testing_resources" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar /*application='Chooseruby'*/);
CREATE TABLE IF NOT EXISTS "development_environments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar /*application='Chooseruby'*/);
CREATE TABLE IF NOT EXISTS "jobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar /*application='Chooseruby'*/);
CREATE TABLE IF NOT EXISTS "frameworks" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar /*application='Chooseruby'*/);
CREATE TABLE IF NOT EXISTS "directories" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar /*application='Chooseruby'*/);
CREATE TABLE IF NOT EXISTS "products" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "name" varchar /*application='Chooseruby'*/);
CREATE TABLE IF NOT EXISTS "author_proposals" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "author_id" integer, "matched_entry_id" integer, "resource_url" text, "original_resource_url" text, "link_updates" text, "bio_text" text, "description_text" text, "author_name" varchar, "submitter_name" varchar, "submitter_email" varchar NOT NULL, "submission_notes" text, "status" integer DEFAULT 0 NOT NULL, "reviewer_id" integer, "admin_comment" text, "reviewed_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_726c9725d7"
FOREIGN KEY ("author_id")
  REFERENCES "authors" ("id")
 ON DELETE CASCADE, CONSTRAINT "fk_rails_5d96ad48b6"
FOREIGN KEY ("matched_entry_id")
  REFERENCES "entries" ("id")
 ON DELETE SET NULL);
CREATE INDEX "index_author_proposals_on_author_id" ON "author_proposals" ("author_id") /*application='Chooseruby'*/;
CREATE INDEX "index_author_proposals_on_matched_entry_id" ON "author_proposals" ("matched_entry_id") /*application='Chooseruby'*/;
CREATE INDEX "index_author_proposals_on_status" ON "author_proposals" ("status") /*application='Chooseruby'*/;
CREATE INDEX "index_author_proposals_on_submitter_email" ON "author_proposals" ("submitter_email") /*application='Chooseruby'*/;
CREATE INDEX "index_author_proposals_on_created_at" ON "author_proposals" ("created_at") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "sessions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "token" varchar NOT NULL, "ip_address" varchar, "user_agent" varchar, "last_active_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_758836b4f0"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
 ON DELETE CASCADE);
CREATE INDEX "index_sessions_on_user_id" ON "sessions" ("user_id") /*application='Chooseruby'*/;
CREATE UNIQUE INDEX "index_sessions_on_token" ON "sessions" ("token") /*application='Chooseruby'*/;
CREATE INDEX "index_sessions_on_last_active_at" ON "sessions" ("last_active_at") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "bans" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer, "ip_address" varchar, "reason" text, "expires_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_070022cd76"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
 ON DELETE CASCADE);
CREATE INDEX "index_bans_on_user_id" ON "bans" ("user_id") /*application='Chooseruby'*/;
CREATE INDEX "index_bans_on_ip_address" ON "bans" ("ip_address") /*application='Chooseruby'*/;
CREATE INDEX "index_bans_on_expires_at" ON "bans" ("expires_at") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "users" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "email_address" varchar NOT NULL, "password_digest" varchar NOT NULL, "name" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "role" varchar DEFAULT 'editor' NOT NULL, "status" varchar DEFAULT 'active' NOT NULL);
CREATE UNIQUE INDEX "index_users_on_email_address" ON "users" ("email_address") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "solid_queue_jobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "queue_name" varchar NOT NULL, "class_name" varchar NOT NULL, "arguments" text, "priority" integer DEFAULT 0 NOT NULL, "active_job_id" varchar, "scheduled_at" datetime(6), "finished_at" datetime(6), "concurrency_key" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE INDEX "index_solid_queue_jobs_on_active_job_id" ON "solid_queue_jobs" ("active_job_id") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_queue_jobs_on_class_name" ON "solid_queue_jobs" ("class_name") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_queue_jobs_on_finished_at" ON "solid_queue_jobs" ("finished_at") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_queue_jobs_for_filtering" ON "solid_queue_jobs" ("queue_name", "finished_at") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_queue_jobs_for_alerting" ON "solid_queue_jobs" ("scheduled_at", "finished_at") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "solid_queue_pauses" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "queue_name" varchar NOT NULL, "created_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_solid_queue_pauses_on_queue_name" ON "solid_queue_pauses" ("queue_name") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "solid_queue_processes" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "kind" varchar NOT NULL, "last_heartbeat_at" datetime(6) NOT NULL, "supervisor_id" bigint, "pid" integer NOT NULL, "hostname" varchar, "metadata" text, "created_at" datetime(6) NOT NULL, "name" varchar NOT NULL);
CREATE INDEX "index_solid_queue_processes_on_last_heartbeat_at" ON "solid_queue_processes" ("last_heartbeat_at") /*application='Chooseruby'*/;
CREATE UNIQUE INDEX "index_solid_queue_processes_on_name_and_supervisor_id" ON "solid_queue_processes" ("name", "supervisor_id") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_queue_processes_on_supervisor_id" ON "solid_queue_processes" ("supervisor_id") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "solid_queue_recurring_tasks" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "schedule" varchar NOT NULL, "command" varchar(2048), "class_name" varchar, "arguments" text, "queue_name" varchar, "priority" integer DEFAULT 0, "static" boolean DEFAULT TRUE NOT NULL, "description" text, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_solid_queue_recurring_tasks_on_key" ON "solid_queue_recurring_tasks" ("key") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_queue_recurring_tasks_on_static" ON "solid_queue_recurring_tasks" ("static") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "solid_queue_semaphores" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "value" integer DEFAULT 1 NOT NULL, "expires_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE INDEX "index_solid_queue_semaphores_on_expires_at" ON "solid_queue_semaphores" ("expires_at") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_queue_semaphores_on_key_and_value" ON "solid_queue_semaphores" ("key", "value") /*application='Chooseruby'*/;
CREATE UNIQUE INDEX "index_solid_queue_semaphores_on_key" ON "solid_queue_semaphores" ("key") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "solid_queue_blocked_executions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "job_id" bigint NOT NULL, "queue_name" varchar NOT NULL, "priority" integer DEFAULT 0 NOT NULL, "concurrency_key" varchar NOT NULL, "expires_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_4cd34e2228"
FOREIGN KEY ("job_id")
  REFERENCES "solid_queue_jobs" ("id")
 ON DELETE CASCADE);
CREATE INDEX "index_solid_queue_blocked_executions_for_release" ON "solid_queue_blocked_executions" ("concurrency_key", "priority", "job_id") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_queue_blocked_executions_for_maintenance" ON "solid_queue_blocked_executions" ("expires_at", "concurrency_key") /*application='Chooseruby'*/;
CREATE UNIQUE INDEX "index_solid_queue_blocked_executions_on_job_id" ON "solid_queue_blocked_executions" ("job_id") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "solid_queue_claimed_executions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "job_id" bigint NOT NULL, "process_id" bigint, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_9cfe4d4944"
FOREIGN KEY ("job_id")
  REFERENCES "solid_queue_jobs" ("id")
 ON DELETE CASCADE);
CREATE UNIQUE INDEX "index_solid_queue_claimed_executions_on_job_id" ON "solid_queue_claimed_executions" ("job_id") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_queue_claimed_executions_on_process_id_and_job_id" ON "solid_queue_claimed_executions" ("process_id", "job_id") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "solid_queue_failed_executions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "job_id" bigint NOT NULL, "error" text, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_39bbc7a631"
FOREIGN KEY ("job_id")
  REFERENCES "solid_queue_jobs" ("id")
 ON DELETE CASCADE);
CREATE UNIQUE INDEX "index_solid_queue_failed_executions_on_job_id" ON "solid_queue_failed_executions" ("job_id") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "solid_queue_ready_executions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "job_id" bigint NOT NULL, "queue_name" varchar NOT NULL, "priority" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_81fcbd66af"
FOREIGN KEY ("job_id")
  REFERENCES "solid_queue_jobs" ("id")
 ON DELETE CASCADE);
CREATE UNIQUE INDEX "index_solid_queue_ready_executions_on_job_id" ON "solid_queue_ready_executions" ("job_id") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_queue_poll_all" ON "solid_queue_ready_executions" ("priority", "job_id") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_queue_poll_by_queue" ON "solid_queue_ready_executions" ("queue_name", "priority", "job_id") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "solid_queue_recurring_executions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "job_id" bigint NOT NULL, "task_key" varchar NOT NULL, "run_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_318a5533ed"
FOREIGN KEY ("job_id")
  REFERENCES "solid_queue_jobs" ("id")
 ON DELETE CASCADE);
CREATE UNIQUE INDEX "index_solid_queue_recurring_executions_on_job_id" ON "solid_queue_recurring_executions" ("job_id") /*application='Chooseruby'*/;
CREATE UNIQUE INDEX "index_solid_queue_recurring_executions_on_task_key_and_run_at" ON "solid_queue_recurring_executions" ("task_key", "run_at") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "solid_queue_scheduled_executions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "job_id" bigint NOT NULL, "queue_name" varchar NOT NULL, "priority" integer DEFAULT 0 NOT NULL, "scheduled_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c4316f352d"
FOREIGN KEY ("job_id")
  REFERENCES "solid_queue_jobs" ("id")
 ON DELETE CASCADE);
CREATE UNIQUE INDEX "index_solid_queue_scheduled_executions_on_job_id" ON "solid_queue_scheduled_executions" ("job_id") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_queue_dispatch_all" ON "solid_queue_scheduled_executions" ("scheduled_at", "priority", "job_id") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "solid_cache_entries" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" blob(1024) NOT NULL, "value" blob(536870912) NOT NULL, "created_at" datetime(6) NOT NULL, "key_hash" integer(8) NOT NULL, "byte_size" integer(4) NOT NULL);
CREATE INDEX "index_solid_cache_entries_on_byte_size" ON "solid_cache_entries" ("byte_size") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_cache_entries_on_key_hash_and_byte_size" ON "solid_cache_entries" ("key_hash", "byte_size") /*application='Chooseruby'*/;
CREATE UNIQUE INDEX "index_solid_cache_entries_on_key_hash" ON "solid_cache_entries" ("key_hash") /*application='Chooseruby'*/;
CREATE TABLE IF NOT EXISTS "solid_cable_messages" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "channel" blob(1024) NOT NULL, "payload" blob(536870912) NOT NULL, "created_at" datetime(6) NOT NULL, "channel_hash" integer(8) NOT NULL);
CREATE INDEX "index_solid_cable_messages_on_channel" ON "solid_cable_messages" ("channel") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_cable_messages_on_channel_hash" ON "solid_cable_messages" ("channel_hash") /*application='Chooseruby'*/;
CREATE INDEX "index_solid_cable_messages_on_created_at" ON "solid_cable_messages" ("created_at") /*application='Chooseruby'*/;
INSERT INTO "schema_migrations" (version) VALUES
('20260116152915'),
('20260116152457'),
('20260116152344'),
('20260111063409'),
('20260110064417'),
('20260110064341'),
('20260110064239'),
('20260102194814'),
('20251212125603'),
('20251212125602'),
('20251212125601'),
('20251212125600'),
('20251212125560'),
('20251212125559'),
('20251212125558'),
('20251212125557'),
('20251212125556'),
('20251212125555'),
('20251212122955'),
('20251206063248'),
('20251206063242'),
('20251206063241'),
('20251206063238'),
('20251206063237'),
('20251206063236'),
('20251206063235'),
('20251206063232'),
('20251206063231'),
('20251206063230'),
('20251206063229'),
('20251206063221'),
('20251128085541'),
('20251127144012'),
('20251127130015'),
('20251127123701'),
('20251126135352'),
('20251124183358'),
('20251124183354'),
('20251103123000'),
('20251103120000'),
('20251102104239'),
('20251102081116'),
('20251102075753'),
('20251102075203'),
('20251102075202'),
('20251102075201'),
('20251102075200'),
('20251102075161'),
('20251102075160'),
('20251102075159'),
('20251102075158'),
('20251102075157'),
('20251102075156'),
('20251102075009'),
('20251101141427'),
('20251101140258'),
('20251101135621'),
('20251101133251');

