# Specification: Authors Feature

## Goal
Create an Authors model and feature to track Ruby community contributors with profile information, social links, and bio. Authors will be associated with resources, enriching the directory with attribution and enabling discovery through creator relationships.

## User Stories
- As a visitor, I want to view author profiles with their bio and social links so that I can learn about resource creators and find their other work
- As a visitor, I want to see all resources by a specific author so that I can discover more content from creators I trust
- As an admin, I want to manage author profiles, approve pending authors, and manually upload avatars so that I can maintain quality author data
- As a resource submitter, I want to select existing authors or suggest new ones when submitting resources so that I can properly attribute content to its creators

## Specific Requirements

**Author Model with Profile Information**
- Name field (required, minimum 2 characters)
- Bio field (optional, plain text only, maximum 500 characters)
- Status enum (pending, approved) to support approval workflow
- Slug field for SEO-friendly URLs
- GitHub username field for avatar auto-fetching
- Ten optional social/web link fields: github_url, gitlab_url, website_url, bluesky_url, ruby_social_url, twitter_url, linkedin_url, youtube_url, twitch_url, blog_url
- All URL fields validate proper URL format when provided
- Timestamps for created_at and updated_at

**Many-to-Many Relationship with Resources**
- Create resources_authors join table with author_id and resource_id foreign keys
- Author has_many :resources, through: :resources_authors association
- Resource has_many :authors, through: :resources_authors association (assumes Resource model exists or will be created)
- Add indexes on both foreign keys in join table for query performance
- Support multiple authors per resource and multiple resources per author

**Avatar Auto-Fetch from GitHub**
- When github_url is saved or updated, extract username and fetch avatar
- Use simple URL construction pattern: https://github.com/{username}.png
- Store avatar_url string in database rather than downloading image
- Implement as Active Record callback (after_save) on Author model
- Handle API failures gracefully with fallback to manual upload
- Cache avatar URL to minimize GitHub API calls
- Consider GitHub rate limits (60 requests/hour unauthenticated)

**Manual Avatar Upload Fallback**
- Use Active Storage for manual avatar uploads when no GitHub username provided
- Support PNG, JPG, GIF image formats
- Configure one-to-one has_one_attached :avatar relationship
- Admin can upload via Avo admin interface
- Display uploaded avatar if present, otherwise display GitHub avatar URL, otherwise show default placeholder

**Avo Admin Interface Configuration**
- Create app/avo/resources/author_resource.rb with code-driven configuration
- Enable full CRUD operations (index, show, new, edit, destroy)
- Configure fields: name (text), bio (textarea), status (select), github_url (text), all social links (text)
- Add avatar upload field using one-line Active Storage configuration
- Implement fuzzy search on name field for author selection
- Add filter by status (approved, pending) on index page
- Display pending authors count badge
- Add custom action to bulk approve pending authors

**Public Author Profile Pages**
- Create AuthorsController with show action
- Route: GET /authors/:slug (use friendly_id gem or custom slug implementation)
- Display author name as h1 heading
- Show avatar (GitHub or uploaded) with alt text of author name
- Render bio in paragraph tag if present
- Display social/web links as icon buttons only for fields with values
- List all approved resources by this author with links to resource detail pages
- Paginate resource list if author has more than 20 resources
- Add meta tags for SEO (title, description using bio excerpt)

**Pending Author Approval Workflow**
- Resource submission form includes author selection/suggestion
- Dropdown shows existing approved authors with fuzzy search
- "Suggest New Author" option creates modal/section with fields: name, bio, github_url, other social links
- Submitting form with new author creates Author record with status: pending
- Pending authors appear in Avo admin interface with pending filter
- Admin can approve (change status to approved) or reject (delete record)
- Approved authors become available in dropdown for future submissions
- Pending authors are associated with submitted resource but not displayed publicly until approved

**URL Validation for Social Links**
- Validate all URL fields (github_url, gitlab_url, website_url, etc.) for proper format
- Allow nil/blank values since all social links are optional
- Use Rails URI validation or custom validator
- Ensure URLs start with http:// or https://
- Provide clear error messages for invalid URLs in admin interface

**Slug Generation for SEO-Friendly URLs**
- Generate slug from name field on create/update
- Use parameterize method to convert name to URL-safe format
- Ensure slug uniqueness with database constraint and validation
- Update slug when name changes (or implement permanent slugs)
- Find authors by slug in AuthorsController#show

**GitHub Avatar Fetching Service**
- Extract GitHub username from github_url (handle various GitHub URL formats)
- Construct avatar URL: https://github.com/{username}.png or use API https://api.github.com/users/{username}
- Implement as concern or service object for reusability
- Handle errors: invalid username, rate limiting, network failures
- Log failures for admin visibility
- Set avatar_url to nil on failure (will trigger manual upload fallback)

## Existing Code to Leverage

**ApplicationRecord Base Class**
- Located at app/models/application_record.rb
- Inherit Author model from ApplicationRecord
- Uses Rails 8.x with primary_abstract_class configuration

**Rails Application Structure**
- Standard Rails 8.1.1 application with Propshaft asset pipeline
- Active Storage already configured via image_processing gem in Gemfile
- Stimulus and Turbo available for any interactive elements needed
- Standard routing configuration in config/routes.rb to extend

**Gemfile Dependencies**
- image_processing gem already included for Active Storage image variants
- Can use for avatar thumbnail generation if needed
- sqlite3 database already configured
- Rails 8.x conventions for enum, validations, and associations apply

**Application CSS Structure**
- Basic CSS manifest at app/assets/stylesheets/application.css
- No Tailwind detected yet but requirements specify using Tailwind CSS
- Will need to add Tailwind CSS gem and configuration for author profile styling

**Layout Template**
- Standard application layout at app/views/layouts/application.html.erb
- Author profile views will extend this layout
- Maintains consistent header, navigation, and footer across all pages

## Out of Scope
- Author authentication or login functionality (authors are profile records, not user accounts)
- Author self-service dashboard or profile editing
- Activity feeds showing recent author updates or contributions
- Author popularity rankings, statistics, or analytics dashboards
- Author-to-author relationships, networks, or collaboration features
- Email notifications sent to authors about their profile or resources
- Author verification badges or official/verified status indicators
- Author following or subscription features for visitors
- Author search on public site (only in admin interface)
- Integration with authentication systems (no author login required)
