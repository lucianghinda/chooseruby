# Task Breakdown: Authors Feature

## Overview
Total Task Groups: 7
Estimated Total Effort: 15-20 hours
Dependencies: Resource model (assumed to exist or will be created in parallel)

## Task List

### Group 1: Foundation - Database Schema & Core Model

#### Task 1.1: Author Model and Migration
**Dependencies:** None
**Effort:** M
**Owner:** database-engineer

- [x] 1.1.0 Complete database layer for Author model
  - [x] 1.1.1 Write 2-8 focused tests for Author model functionality
    - Test name presence and minimum length validation
    - Test bio maximum length validation (500 chars)
    - Test status enum (pending, approved)
    - Test slug generation and uniqueness
    - Test URL validation for at least one social link field
    - Skip exhaustive testing of all validations and methods
  - [x] 1.1.2 Generate Author model and migration
    - Fields: name (string, not null), bio (text), status (integer, default: 0), slug (string, unique index), avatar_url (string)
    - GitHub field: github_url (string)
    - Social link fields: gitlab_url, website_url, bluesky_url, ruby_social_url, twitter_url, linkedin_url, youtube_url, twitch_url, blog_url (all strings)
    - Timestamps: created_at, updated_at
    - Add index on name for search performance
    - Add index on status for filtering
    - Add unique index on slug
  - [x] 1.1.3 Configure Author model validations
    - Validate name presence and minimum 2 characters
    - Validate bio maximum 500 characters
    - Define status enum: { pending: 0, approved: 1 }
    - Validate slug presence and uniqueness
    - Create custom URL validator for all URL fields (optional, must be valid format with http/https)
  - [x] 1.1.4 Implement slug generation
    - Use before_validation callback to generate slug from name using parameterize
    - Ensure slug uniqueness by appending number if needed
    - Handle slug updates when name changes
  - [x] 1.1.5 Configure Active Storage for avatar
    - Add has_one_attached :avatar association
    - Validate attachment content type (PNG, JPG, GIF)
    - Validate attachment size (max 5MB)
  - [x] 1.1.6 Run database layer tests
    - Execute ONLY the 2-8 tests written in 1.1.1
    - Verify migrations run successfully
    - Do NOT run entire test suite

**Acceptance Criteria:**
- Author migration creates table with all required fields
- Model validations enforce name, bio length, URL formats
- Slug auto-generates from name and ensures uniqueness
- Status enum works with pending/approved values
- Active Storage configured for avatar uploads
- Database layer tests (2-8 tests) pass

---

#### Task 1.2: Join Table for Author-Resource Relationship
**Dependencies:** Task 1.1, Resource model exists
**Effort:** S
**Owner:** database-engineer

- [x] 1.2.0 Complete resources_authors join table
  - [x] 1.2.1 Write 2-4 focused tests for associations
    - Test Author has_many :resources relationship
    - Test Resource has_many :authors relationship (if Resource model exists)
    - Test multiple authors per resource
    - Skip exhaustive edge cases
  - [x] 1.2.2 Create resources_authors join table migration
    - Fields: author_id (integer, foreign key), resource_id (integer, foreign key)
    - Timestamps: created_at, updated_at
    - Add index on author_id for query performance
    - Add index on resource_id for query performance
    - Add composite unique index on [author_id, resource_id] to prevent duplicates
    - Add foreign key constraints with on_delete: cascade
  - [x] 1.2.3 Configure Author associations
    - Add has_many :resources_authors
    - Add has_many :resources, through: :resources_authors
    - Add scope :approved to filter by status
  - [x] 1.2.4 Update Resource model associations (if exists)
    - Add has_many :resources_authors
    - Add has_many :authors, through: :resources_authors
  - [x] 1.2.5 Run association tests
    - Execute ONLY the 2-4 tests written in 1.2.1
    - Verify associations work correctly
    - Do NOT run entire test suite

**Acceptance Criteria:**
- Join table migration creates resources_authors with proper indexes
- Author can have multiple resources
- Resource can have multiple authors
- Foreign key constraints enforce referential integrity
- Association tests (2-4 tests) pass

---

### Group 2: GitHub Avatar Service Layer

#### Task 2.1: GitHub Avatar Fetching Service
**Dependencies:** Task 1.1
**Effort:** M
**Owner:** backend-engineer

- [x] 2.1.0 Complete GitHub avatar fetching service
  - [x] 2.1.1 Write 2-8 focused tests for avatar service
    - Test extracting username from various GitHub URL formats
    - Test successful avatar URL construction
    - Test handling of invalid GitHub URL
    - Test fallback when fetch fails
    - Skip exhaustive error scenario testing
  - [x] 2.1.2 Create GithubAvatarService class
    - Location: app/services/github_avatar_service.rb
    - Method: call(github_url) returns avatar URL or nil
    - Extract username from github_url (handle formats: github.com/username, github.com/username/, etc.)
    - Construct avatar URL: https://github.com/{username}.png
    - Validate URL returns 200 status (optional check)
    - Handle errors gracefully and return nil on failure
    - Log failures with Rails.logger.warn for admin visibility
  - [x] 2.1.3 Integrate service into Author model
    - Add after_save callback :fetch_github_avatar
    - Callback should only run if github_url changed
    - Call GithubAvatarService and update avatar_url field
    - Skip callback if github_url is blank
    - Avoid infinite loop by using update_column for avatar_url
  - [x] 2.1.4 Add caching mechanism
    - Only re-fetch if github_url actually changed
    - Store avatar_url in database to minimize API calls
    - Consider rate limiting (60 req/hour for unauthenticated)
  - [x] 2.1.5 Run service layer tests
    - Execute ONLY the 2-8 tests written in 2.1.1
    - Verify avatar URL is fetched and stored
    - Do NOT run entire test suite

**Acceptance Criteria:**
- GithubAvatarService extracts username from various URL formats
- Service constructs correct avatar URL pattern
- Author model callback fetches avatar on github_url change
- Failures are logged and don't break author creation
- avatar_url is cached in database
- Service layer tests (2-8 tests) pass

---

### Group 3: Avo Admin Interface

#### Task 3.1: Avo Installation and Configuration
**Dependencies:** Task 1.1, Task 1.2
**Effort:** M
**Owner:** backend-engineer

- [x] 3.1.0 Complete Avo installation and setup
  - [x] 3.1.1 Write 2-4 focused tests for Avo configuration
    - Test Author resource is accessible in admin
    - Test basic CRUD operations work
    - Skip exhaustive admin workflow testing
  - [x] 3.1.2 Add Avo gem to Gemfile
    - Add gem 'avo' with appropriate version
    - Run bundle install
    - Reference: https://avohq.io/llms.txt
  - [x] 3.1.3 Run Avo installer
    - Execute rails generate avo:install
    - Configure Avo initializer if needed
    - Set up admin authentication (basic for now)
  - [x] 3.1.4 Configure Avo routes
    - Mount Avo engine in config/routes.rb
    - Typically: mount Avo::Engine, at: Avo.configuration.root_path
  - [x] 3.1.5 Run Avo configuration tests
    - Execute ONLY the 2-4 tests written in 3.1.1
    - Verify Avo mounts correctly
    - Do NOT run entire test suite

**Acceptance Criteria:**
- Avo gem installed and configured
- Avo admin accessible at configured path
- Basic authentication works
- Avo configuration tests (2-4 tests) pass

---

#### Task 3.2: Author Resource Configuration in Avo
**Dependencies:** Task 3.1
**Effort:** L
**Owner:** backend-engineer

- [x] 3.2.0 Complete Avo Author resource configuration
  - [x] 3.2.1 Write 2-8 focused tests for Author resource features
    - Test search by name works
    - Test status filter (approved/pending)
    - Test bulk approve action
    - Test avatar upload field displays
    - Skip exhaustive field and action testing
  - [x] 3.2.2 Generate Avo Author resource
    - Run: rails generate avo:resource author
    - Location: app/avo/resources/author_resource.rb
  - [x] 3.2.3 Configure Author resource fields
    - field :name, as: :text, required: true
    - field :bio, as: :textarea, rows: 5
    - field :status, as: :select, enum: Author.statuses
    - field :slug, as: :text, readonly: true (show auto-generated slug)
    - field :avatar, as: :file (Active Storage integration)
    - field :avatar_url, as: :text, readonly: true (show GitHub-fetched URL)
    - field :github_url, as: :text
    - field :gitlab_url, as: :text
    - field :website_url, as: :text
    - field :bluesky_url, as: :text
    - field :ruby_social_url, as: :text
    - field :twitter_url, as: :text
    - field :linkedin_url, as: :text
    - field :youtube_url, as: :text
    - field :twitch_url, as: :text
    - field :blog_url, as: :text
  - [x] 3.2.4 Configure search functionality
    - Add self.search = { query: -> { query.where("name LIKE ?", "%#{params[:q]}%") } }
    - Enable fuzzy search on name field
  - [x] 3.2.5 Add status filter
    - filter :status, with: :select, enum: Author.statuses
    - Add pending authors count badge on index
  - [x] 3.2.6 Create bulk approve action
    - Create app/avo/actions/approve_authors.rb
    - Action changes status from pending to approved
    - Available on index page for batch selection
    - Show success message after approval
  - [x] 3.2.7 Configure index page display
    - Show: name, status, github_url, created_at
    - Add badge for pending status
    - Sort by created_at desc by default
  - [x] 3.2.8 Run Author resource tests
    - Execute ONLY the 2-8 tests written in 3.2.1
    - Verify search, filters, and actions work
    - Do NOT run entire test suite

**Acceptance Criteria:**
- Author resource displays all fields in Avo admin
- Search by name works with fuzzy matching
- Status filter shows approved/pending authors
- Bulk approve action changes status correctly
- Avatar upload field integrated via Active Storage
- Pending authors count badge displays
- Author resource tests (2-8 tests) pass

---

### Group 4: Public Author Profile Pages

#### Task 4.1: Authors Controller and Routes
**Dependencies:** Task 1.1, Task 1.2
**Effort:** M
**Owner:** backend-engineer

- [x] 4.1.0 Complete Authors controller and routing
  - [x] 4.1.1 Write 2-8 focused tests for AuthorsController
    - Test show action renders for approved author
    - Test show action returns 404 for pending author
    - Test show action handles invalid slug
    - Test resources are loaded correctly
    - Skip exhaustive edge case testing
  - [x] 4.1.2 Create AuthorsController
    - Generate: rails generate controller Authors show
    - Location: app/controllers/authors_controller.rb
    - Implement show action
  - [x] 4.1.3 Configure show action logic
    - Find author by slug: Author.find_by!(slug: params[:slug])
    - Only display approved authors (filter by status: approved)
    - Return 404 for pending authors
    - Eager load resources association to avoid N+1
    - Load approved resources only
    - Handle author not found with 404
  - [x] 4.1.4 Add pagination for resources
    - Paginate author.resources with 20 per page
    - Use kaminari or will_paginate gem
    - Display pagination controls if > 20 resources
  - [x] 4.1.5 Configure routes
    - Add: get '/authors/:slug', to: 'authors#show', as: :author
    - Use slug instead of id for SEO-friendly URLs
  - [x] 4.1.6 Run controller tests
    - Execute ONLY the 2-8 tests written in 4.1.1
    - Verify show action and routing work
    - Do NOT run entire test suite

**Acceptance Criteria:**
- AuthorsController#show finds author by slug
- Only approved authors are publicly visible
- Pending authors return 404
- Resources are eager loaded and paginated
- Routes use SEO-friendly slugs
- Controller tests (2-8 tests) pass

---

#### Task 4.2: Author Profile View Template
**Dependencies:** Task 4.1
**Effort:** L
**Owner:** ui-designer

- [x] 4.2.0 Complete author profile view template
  - [x] 4.2.1 Write 2-8 focused tests for author profile rendering
    - Test author name displays as h1
    - Test avatar displays with correct alt text
    - Test social links render for provided URLs
    - Test resources list displays correctly
    - Skip exhaustive rendering scenarios
  - [x] 4.2.2 Create author show view template
    - Location: app/views/authors/show.html.erb
    - Extend application layout
    - Follow existing design system patterns
  - [x] 4.2.3 Implement author header section
    - Display author avatar (uploaded or GitHub URL)
    - Avatar alt text: @author.name
    - Use default placeholder if no avatar: https://via.placeholder.com/150?text=No+Avatar
    - Display author name as <h1> heading
    - Show bio in <p> tag if present
  - [x] 4.2.4 Implement social links section
    - Display social/web links as icon buttons
    - Only show links where URL is present (conditional rendering)
    - Use iconography for each platform (consider heroicons or font awesome)
    - Links open in new tab (target="_blank" rel="noopener")
    - Layout: horizontal row of icon buttons
  - [x] 4.2.5 Implement resources list section
    - Heading: "Resources by [Author Name]"
    - Display each resource with title and link to resource detail page
    - Show resource count if > 0
    - Display message if no resources: "No resources yet"
    - Include pagination controls if > 20 resources
  - [x] 4.2.6 Add SEO meta tags
    - Set page title: "[Author Name] | ChooseRuby Authors"
    - Add meta description using bio excerpt (first 160 chars)
    - Add Open Graph tags for social sharing
  - [x] 4.2.7 Run view rendering tests
    - Execute ONLY the 2-8 tests written in 4.2.1
    - Verify key elements render correctly
    - Do NOT run entire test suite

**Acceptance Criteria:**
- Author name displays as h1 heading
- Avatar displays (uploaded, GitHub, or placeholder)
- Bio renders if present
- Social links display as icon buttons for provided URLs only
- Resources list shows approved resources with pagination
- SEO meta tags configured correctly
- View rendering tests (2-8 tests) pass

---

#### Task 4.3: Author Profile Styling
**Dependencies:** Task 4.2
**Effort:** M
**Owner:** ui-designer

- [x] 4.3.0 Complete author profile styling
  - [x] 4.3.1 Install Tailwind CSS (if not already installed)
    - Add tailwindcss-rails gem to Gemfile
    - Run: rails tailwindcss:install
    - Configure Tailwind for author profile styles
  - [x] 4.3.2 Style author header section
    - Avatar: circular, 150px width, center-aligned
    - Name: large heading font, bold, centered
    - Bio: medium text, centered, max-width for readability
    - Use spacing utilities for vertical rhythm
  - [x] 4.3.3 Style social links section
    - Icon buttons: consistent size (40px x 40px)
    - Hover states: subtle scale or color change
    - Spacing: gap between icons
    - Layout: flexbox horizontal row, center-aligned
    - Responsive: wrap on mobile if needed
  - [x] 4.3.4 Style resources list section
    - Card-based layout for each resource
    - Resource title: medium heading, linked with hover state
    - Consistent spacing between resources
    - Pagination controls: centered, styled buttons
  - [x] 4.3.5 Implement responsive design
    - Mobile (< 768px): single column, stacked layout
    - Tablet (768px - 1024px): optimized spacing
    - Desktop (> 1024px): max-width container, centered
  - [x] 4.3.6 Add loading and empty states
    - Loading state for avatar if GitHub fetch in progress
    - Empty state for no resources
    - Placeholder avatar styling
  - [x] 4.3.7 Manual testing of styling
    - View profile on mobile, tablet, desktop viewports
    - Test with author having all fields populated
    - Test with author having minimal fields
    - Verify hover states and interactions

**Acceptance Criteria:**
- Author profile matches design system aesthetics
- Responsive design works across mobile, tablet, desktop
- Social icons have consistent sizing and hover states
- Resources list is readable and well-spaced
- Loading and empty states handled gracefully
- Manual testing confirms visual quality

---

### Group 5: Resource Submission Form Integration

#### Task 5.1: Author Selection in Resource Submission Form
**Dependencies:** Task 1.1, Task 1.2, Resource submission form exists
**Effort:** L
**Owner:** ui-designer, backend-engineer

- [ ] 5.1.0 Complete author selection in resource form
  - [ ] 5.1.1 Write 2-8 focused tests for author selection
    - Test approved authors appear in dropdown
    - Test pending authors excluded from dropdown
    - Test search/filter functionality
    - Test "Suggest New Author" creates pending record
    - Skip exhaustive form interaction testing
  - [ ] 5.1.2 Add author selection dropdown to resource form
    - Location: app/views/resources/_form.html.erb (or equivalent)
    - Use select2 or tom-select for searchable dropdown
    - Load approved authors only: Author.approved.order(:name)
    - Enable search/filter by author name
    - Allow multiple author selection (if resource has multiple authors)
  - [ ] 5.1.3 Implement "Suggest New Author" option
    - Add button/link: "Can't find author? Suggest a new one"
    - Opens modal or expands inline form section
    - Use Stimulus controller for show/hide behavior
  - [ ] 5.1.4 Create new author suggestion form
    - Fields: name (required), bio (optional), github_url (optional), other social links (optional)
    - Submission creates Author with status: pending
    - Associate pending author with resource being submitted
    - Show success message: "Author suggestion submitted for review"
  - [ ] 5.1.5 Update ResourcesController create/update actions
    - Handle author_ids parameter for existing authors
    - Handle new_author_attributes parameter for suggested authors
    - Create pending authors and associate with resource
    - Validate author associations
  - [ ] 5.1.6 Run author selection tests
    - Execute ONLY the 2-8 tests written in 5.1.1
    - Verify dropdown and suggestion workflow
    - Do NOT run entire test suite

**Acceptance Criteria:**
- Resource form has searchable author dropdown
- Dropdown shows only approved authors
- "Suggest New Author" opens form for new author
- New author suggestion creates pending Author record
- Pending author associated with submitted resource
- Author selection tests (2-8 tests) pass

**Note:** Skipped - Resource submission form does not exist yet. This will be implemented when the Resource submission feature is built.

---

### Group 6: Testing - Review & Gap Analysis

#### Task 6.1: Test Review and Critical Gap Filling
**Dependencies:** Tasks 1.1-5.1 (all previous task groups)
**Effort:** M
**Owner:** test-engineer

- [x] 6.1.0 Review existing tests and fill critical gaps only
  - [x] 6.1.1 Review tests from all previous task groups
    - Review Task 1.1.1: Author model tests (2-8 tests)
    - Review Task 1.2.1: Association tests (2-4 tests)
    - Review Task 2.1.1: GitHub avatar service tests (2-8 tests)
    - Review Task 3.1.1: Avo configuration tests (2-4 tests)
    - Review Task 3.2.1: Author resource tests (2-8 tests)
    - Review Task 4.1.1: AuthorsController tests (2-8 tests)
    - Review Task 4.2.1: View rendering tests (2-8 tests)
    - Review Task 5.1.1: Author selection tests (2-8 tests)
    - Total existing tests: approximately 18-48 tests
  - [x] 6.1.2 Analyze test coverage gaps for Authors feature only
    - Identify critical user workflows lacking coverage:
      - End-to-end: Submit resource with new author suggestion → Admin approves → Author appears on public profile
      - End-to-end: GitHub avatar fetching → Display on profile page
      - Integration: Resource deletion cascades to join table
      - Edge case: Author with no resources displays correctly
    - Focus ONLY on gaps related to Authors feature requirements
    - Do NOT assess entire application test coverage
    - Prioritize end-to-end workflows over unit test gaps
  - [x] 6.1.3 Write up to 10 additional strategic tests maximum
    - Add maximum of 10 new tests to fill identified critical gaps
    - Example critical tests:
      - Integration test: Pending author approval workflow end-to-end
      - Integration test: GitHub avatar fetch and display pipeline
      - System test: Visitor views author profile with all sections
      - System test: Admin bulk approves pending authors
      - Integration test: Resource with multiple authors displays all on detail page
    - Focus on integration points and end-to-end workflows
    - Do NOT write comprehensive coverage for all scenarios
    - Skip edge cases, performance tests, accessibility tests unless business-critical
  - [x] 6.1.4 Run feature-specific tests only
    - Run ONLY tests related to Authors feature (tests from 1.1.1, 1.2.1, 2.1.1, 3.1.1, 3.2.1, 4.1.1, 4.2.1, 5.1.1, and 6.1.3)
    - Expected total: approximately 28-58 tests maximum
    - Do NOT run entire application test suite
    - Verify critical workflows pass
    - Fix any failing tests

**Acceptance Criteria:**
- All Authors feature-specific tests pass (approximately 28-58 tests total)
- Critical user workflows for Authors feature are covered
- No more than 10 additional tests added when filling testing gaps
- Testing focused exclusively on Authors feature requirements
- End-to-end workflows verified (suggestion → approval → display)

---

### Group 7: Documentation & Cleanup

#### Task 7.1: Feature Documentation and Code Cleanup
**Dependencies:** Task 6.1
**Effort:** S
**Owner:** backend-engineer

- [ ] 7.1.0 Complete documentation and cleanup
  - [ ] 7.1.1 Document Author model and associations
    - Add comprehensive comments to app/models/author.rb
    - Document validations, callbacks, associations
    - Add usage examples in comments
  - [ ] 7.1.2 Document GithubAvatarService
    - Add class-level documentation explaining purpose
    - Document public methods with parameters and return values
    - Add usage examples
  - [ ] 7.1.3 Update README (if needed)
    - Document Authors feature in main README
    - Explain admin approval workflow
    - Note GitHub avatar auto-fetch functionality
  - [ ] 7.1.4 Create admin user guide
    - Document how to manage authors in Avo
    - Explain pending author approval process
    - Document bulk approve action usage
  - [ ] 7.1.5 Code cleanup
    - Remove any commented-out code
    - Ensure consistent code style
    - Run Rubocop or linter if configured
    - Remove unused imports/dependencies
  - [ ] 7.1.6 Database cleanup
    - Verify all migrations are reversible
    - Ensure proper indexes exist
    - Check foreign key constraints are correct

**Acceptance Criteria:**
- Author model has clear documentation
- GithubAvatarService documented with usage examples
- Admin user guide created for managing authors
- Code style consistent and clean
- All migrations reversible
- No Rubocop violations (if configured)

**Note:** User chose to skip this task group. Models already have good inline documentation. Additional project documentation can be added later if needed.

---

## Execution Order

Recommended implementation sequence:

1. **Group 1: Foundation** (Tasks 1.1-1.2) - Database schema and core Author model - COMPLETED
2. **Group 2: GitHub Service** (Task 2.1) - Avatar fetching service layer - COMPLETED
3. **Group 3: Avo Admin** (Tasks 3.1-3.2) - Admin interface for managing authors - COMPLETED
4. **Group 4: Public Pages** (Tasks 4.1-4.3) - Public-facing author profiles - COMPLETED
5. **Group 5: Resource Integration** (Task 5.1) - Author selection in resource submission - SKIPPED (Resource form doesn't exist yet)
6. **Group 6: Testing** (Task 6.1) - Test review and critical gap filling - COMPLETED
7. **Group 7: Documentation** (Task 7.1) - Documentation and cleanup - SKIPPED (User decision)

## Dependencies Summary

- **Task 1.2 depends on:** Task 1.1 (Author model), Resource model existence
- **Task 2.1 depends on:** Task 1.1 (Author model with github_url field)
- **Task 3.1 depends on:** Task 1.1, Task 1.2 (complete data layer)
- **Task 3.2 depends on:** Task 3.1 (Avo installation)
- **Task 4.1 depends on:** Task 1.1, Task 1.2 (Author model and associations)
- **Task 4.2 depends on:** Task 4.1 (AuthorsController)
- **Task 4.3 depends on:** Task 4.2 (view templates)
- **Task 5.1 depends on:** Task 1.1, Task 1.2, Resource submission form existence
- **Task 6.1 depends on:** All previous task groups (1-5)
- **Task 7.1 depends on:** Task 6.1 (all functionality complete)

## Notes

- **Resource Model Assumption:** This task breakdown assumes a Resource model exists or will be created in parallel. If it doesn't exist, Task 1.2 and Task 5.1 will need to be adjusted or delayed.
- **Avo Reference:** All Avo-related tasks reference https://avohq.io/llms.txt for implementation guidance.
- **Testing Philosophy:** Each task group writes 2-8 focused tests during development, with a final test review phase (Group 6) adding up to 10 additional strategic tests to fill critical gaps.
- **Effort Estimates:** S = Small (1-2 hours), M = Medium (3-4 hours), L = Large (5-6 hours)
- **Pagination Gem:** Task 4.1.4 requires choosing between kaminari or will_paginate - recommend kaminari for Rails 8 compatibility.
- **Tailwind CSS:** Task 4.3 assumes Tailwind CSS will be used per requirements. If not already installed, include installation step.
- **Active Storage:** Already configured per spec, so avatar uploads should work out of the box.
- **GitHub Rate Limiting:** Consider implementing a background job for avatar fetching in production to handle rate limits gracefully.
