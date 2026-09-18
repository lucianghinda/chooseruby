--
-- PostgreSQL database dump (trimmed fixture)
--

COPY "public"."tags" ("id", "title", "created_at", "updated_at", "slug") FROM stdin;
1	Ruby on Rails 7	2022-06-19 09:25:01.836774	2022-06-19 20:30:46.889638	ruby-on-rails-7
2	Hotwire	2022-06-19 09:25:07.218372	2022-06-19 20:30:46.898046	hotwire
\.

COPY "public"."authors" ("id", "name", "twitter_url", "github_url", "website_url", "created_at", "updated_at", "slug") FROM stdin;
1	Jane Author	https://twitter.com/jane	\N	http://jane.example.com	2022-06-19 12:14:28.172832	2022-06-19 20:23:12.355858	jane-author
2	Tabs\tAnd\nNewlines\\Backslash	\N	\N		2022-06-19 12:14:28.172832	2022-06-19 20:23:12.355858	tabs
3	Malformed row with too few columns
\.

COPY "public"."books" ("id", "title", "content", "slug", "isbn", "year", "page", "amazon_url", "website_url", "free", "featured", "created_at", "updated_at") FROM stdin;
1	Modern Front-End Development for Rails	A book about Rails front-ends.	modern-front-end-development-for-rails	9781680507218	2022	408		https://pragprog.com/titles/nrclient2/	f	t	2022-06-19 09:24:14.950515	2022-08-15 14:48:44.738082
\.

COPY "public"."courses" ("id", "title", "content", "slug", "website_url", "free", "created_at", "updated_at") FROM stdin;
1	Rails Course	\N	rails-course	https://example.com/rails-course	t	2022-06-19 09:24:14.950515	2022-08-15 14:48:44.738082
\.

COPY "public"."newsletters" ("id", "title", "content", "slug", "website_url", "created_at", "updated_at") FROM stdin;
1	Ruby Weekly	\N	ruby-weekly	https://rubyweekly.com	2022-06-19 09:24:14.950515	2022-08-15 14:48:44.738082
\.

COPY "public"."podcasts" ("id", "title", "content", "slug", "website_url", "created_at", "updated_at") FROM stdin;
1	Remote Ruby	\N	remote-ruby	https://remoteruby.com	2022-06-19 09:24:14.950515	2022-08-15 14:48:44.738082
\.

COPY "public"."communities" ("id", "title", "content", "slug", "website_url", "platform_type", "members", "created_at", "updated_at") FROM stdin;
1	Ruby Discord	\N	ruby-discord	https://discord.gg/ruby	discord	1000	2022-06-19 09:24:14.950515	2022-08-15 14:48:44.738082
\.

COPY "public"."youtubes" ("id", "title", "content", "slug", "website_url", "created_at", "updated_at") FROM stdin;
1	GoRails	\N	gorails	https://youtube.com/gorails	2022-06-19 09:24:14.950515	2022-08-15 14:48:44.738082
\.

COPY "public"."screencasts" ("id", "title", "content", "slug", "website_url", "created_at", "updated_at") FROM stdin;
1	Drifting Ruby	\N	drifting-ruby	https://driftingruby.com	2022-06-19 09:24:14.950515	2022-08-15 14:48:44.738082
\.

COPY "public"."lessons" ("id", "title", "content", "slug", "url", "youtube_id", "created_at", "updated_at") FROM stdin;
1	Static pages	\N	static-pages	MwbmKqdDsyI	1	2022-09-14 17:39:06.589419	2022-09-14 17:39:06.592033
\.

COPY "public"."authorings" ("id", "author_id", "authorabble_type", "authorabble_id", "created_at", "updated_at") FROM stdin;
1	1	Book	1	2022-06-19 09:25:40.342779	2022-06-19 09:25:40.342779
\.

COPY "public"."taggings" ("id", "tag_id", "taggable_type", "taggable_id", "created_at", "updated_at") FROM stdin;
1	1	Book	1	2022-06-19 09:25:40.28688	2022-06-19 09:25:40.28688
\.
