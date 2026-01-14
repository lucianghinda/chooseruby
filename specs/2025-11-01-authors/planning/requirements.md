# Spec Requirements: Authors Feature

## Initial Description
Build an Authors model and feature that keeps author profiles with the following information:
- Name
- GitHub or GitLab account
- Main website
- Other important links
- Bio of the author

## Product Context

### How This Feature Fits the Product Mission
ChooseRuby is a comprehensive, curated directory helping Ruby developers discover and access the best resources in the Ruby ecosystem. The Authors feature supports this mission by:

- **Connecting Resources to People**: Many Ruby resources (gems, articles, courses, books) are created by notable community members. Linking resources to their authors helps users discover quality work from trusted creators.

- **Building Trust**: Author profiles with bios and social links add credibility to submitted resources and help users evaluate the expertise behind recommendations.

- **Community Recognition**: Showcasing authors acknowledges contributors to the Ruby ecosystem, supporting the product's goal of strengthening the Ruby community.

- **Discovery Paths**: Author pages create an additional discovery mechanism - users can find all resources by a favorite author or expert.

### Relationship to Existing Roadmap
The Authors feature is foundational infrastructure that enhances several roadmap items:

- **Items 1-3 (Core Resource Model, Directory, Detail Pages)**: Authors will be associated with resources, enriching resource detail pages with author information.

- **Item 5 (Community Submission Form)**: Submitters will be able to reference existing authors or suggest new ones when submitting resources.

- **Item 6 (Curation Workflow)**: Admin review will include approving suggested new authors.

- **Item 12 (Community Ratings)**: Author reputation can inform how users evaluate resource quality.

This feature should be implemented early to ensure resources can be properly attributed from the start.

### Technical Alignment
- Ruby on Rails with Active Record for Author model
- Avo admin framework for admin interface (aligned with vanilla Rails approach)
- Stimulus for any interactive elements on public author pages
- Tailwind CSS for styling author profile pages
- SQLite for data storage
- Active Storage for avatar/photo uploads (fallback option)

## Requirements Discussion

### First Round Questions

**Q1:** What social media or web platforms should authors be able to link to?
**Answer:** Complete list of platforms:
- GitHub
- GitLab
- Main website
- Bluesky
- Ruby.social
- Twitter/X
- LinkedIn
- YouTube
- Twitch
- Personal blog

**Q2:** For the bio field, should we support rich text formatting (bold, italics, links) or keep it as plain text?
**Answer:** Plain text only with a maximum of 500 characters to keep profiles concise.

**Q3:** When a user submits a resource and wants to reference an author who doesn't exist yet, what should happen?
**Answer:** Create a "pending author" record that can be accepted or rejected by the admin (Option A from the choices provided).

**Q4:** Should we automatically fetch author avatars from GitHub if a GitHub username is provided, or require manual uploads?
**Answer:** Automatically fetch the GitHub avatar if GitHub username is provided. If no GitHub username, admin should be able to upload the photo manually. Auto-fetch as default, manual upload as fallback.

**Q5:** For the admin interface, should we build custom admin views or use a framework like Avo or Rails Admin to speed up development?
**Answer:** Use Avo for all admin-related tasks to speed up project release. Reference: https://avohq.io/llms.txt

**Q6:** What should be displayed on the public-facing author profile page?
**Answer:** Display author bio, all social/web links, and list all resources authored by this author.

**Q7:** Should there be any restrictions on who can be added as an author, or validation requirements?
**Answer:** Initially only admins create/manage author profiles via Avo admin interface. Authors suggested through resource submissions create pending records requiring admin approval.

**Q8:** Are there any features explicitly OUT of scope for this initial version?
**Answer:**
- No author verification/authentication (authors don't log in)
- No activity feeds
- No author rankings/statistics

### Existing Code to Reference

No similar existing features identified for reference. This is a foundational feature being built early in the product lifecycle.

### Follow-up Questions

None required - all requirements were clearly specified in the initial response.

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
Not applicable - no visual files to analyze.

## Requirements Summary

### Functional Requirements

**Author Model:**
- Name (required field)
- Bio (optional, plain text, max 500 characters)
- Avatar/Photo:
  - Auto-fetch from GitHub if GitHub username provided
  - Manual upload capability if no GitHub username
  - Use Active Storage for manual uploads
- Social/Web Link Fields (all optional):
  - github_url
  - gitlab_url
  - website_url
  - bluesky_url
  - ruby_social_url
  - twitter_url
  - linkedin_url
  - youtube_url
  - twitch_url
  - blog_url

**Relationships:**
- Many-to-many relationship with Resources (Author has_many Resources through join table, Resource has_many Authors through join table)
- Two types of author records:
  - Approved authors (status: 'approved')
  - Pending authors (status: 'pending') - awaiting admin review

**Admin Interface (Avo):**
- Full CRUD operations for authors
- View and manage pending author suggestions
- Approve or reject pending authors
- Upload author avatars manually when needed
- Search authors by name
- Filter authors by status (approved/pending)

**Public Author Pages:**
- URL structure: `/authors/:id` or `/authors/:slug`
- Display sections:
  - Author name and avatar
  - Bio (if provided)
  - Social/web links (display only those provided)
  - List of all approved resources by this author (with links to resource detail pages)

**Resource Submission Integration:**
- Submitters can select from existing approved authors (searchable dropdown)
- Submitters can suggest new authors by providing:
  - Name (required)
  - Optional fields: bio, GitHub username, other links
- New author suggestions create pending author records
- Admin reviews pending authors in Avo interface
- Upon approval, pending author becomes approved and is linked to the submitted resource

**Avatar/Photo Handling:**
- Primary method: Auto-fetch from GitHub API using GitHub username
  - Fetch when GitHub username is saved/updated
  - Cache the avatar URL or store the image
- Fallback method: Admin manual upload via Active Storage
  - Available in Avo admin interface
  - Triggered when no GitHub username provided
  - Supports common image formats (PNG, JPG, GIF)

### Reusability Opportunities

No existing components identified to reuse (early product stage). Future opportunities:
- The Avo admin pattern established here can be replicated for other admin interfaces
- The pending/approved status pattern could be reused for other user-submitted entities
- The GitHub API integration pattern could inform future third-party API integrations

### Scope Boundaries

**In Scope:**
- Author model with profile information and social links
- Many-to-many relationship between Authors and Resources
- Avo admin interface for managing authors
- Public author profile pages
- Pending author workflow for community suggestions
- Auto-fetch GitHub avatars with manual upload fallback
- Integration with resource submission form

**Out of Scope:**
- Author authentication/login (authors are profiles, not users)
- Author dashboard or self-management
- Activity feeds showing author updates
- Author ranking or popularity metrics
- Author-to-author relationships or networks
- Email notifications to authors
- Author verification or badge system
- Author statistics or analytics
- Following/subscribing to authors

**Future Enhancements Mentioned:**
- Could add author statistics if analytics feature is built (roadmap item 15)
- Could integrate with user accounts feature if authors become users (roadmap item 11)
- Could add author rankings if community ratings are expanded (roadmap item 12)

### Technical Considerations

**Technology Stack:**
- Ruby on Rails 8.x
- Active Record for Author model and associations
- Avo admin framework for admin interface
- Active Storage for manual avatar uploads
- GitHub API for auto-fetching avatars
- Stimulus (if needed for any interactive elements)
- Tailwind CSS for styling author profile pages
- SQLite database

**Avo Framework Integration:**
- Avo provides "code driven configuration" through Ruby
- One-line Active Storage configuration for file uploads
- Built-in search functionality for fuzzy-searchable author selection
- Pundit-based authorization for admin access
- No modification to core application codebase required
- Mobile-responsive admin interface included

**GitHub API Integration:**
- Use GitHub username to construct avatar URL
- Pattern: `https://github.com/{username}.png`
- Or use GitHub API: `https://api.github.com/users/{username}`
- Consider rate limiting for API calls
- Implement fallback if GitHub fetch fails
- Cache avatar URLs to minimize API calls

**Database Schema Considerations:**
- authors table with columns for all fields
- resources_authors join table for many-to-many
- Add status column (enum: pending, approved) for author approval workflow
- Add slug column for friendly URLs on author pages
- Consider indexes on name and status for performance

**Validation Requirements:**
- Name: required, minimum 2 characters
- Bio: optional, maximum 500 characters
- URL fields: optional, must be valid URL format if provided
- At least one of GitHub username or manual avatar should be provided (nice to have, not required)

**Integration Points:**
- Resource submission form must include author selection/suggestion
- Resource detail pages should link to author profiles
- Admin review workflow must handle both resource and author approvals
- Consider how this affects existing Resource model if already implemented

**Performance Considerations:**
- Eager load authors when displaying resources to avoid N+1 queries
- Cache author avatars fetched from GitHub
- Index author names for search performance
- Consider pagination for author resource lists if an author has many resources

**Error Handling:**
- Gracefully handle GitHub API failures (use manual upload as fallback)
- Validate URLs before saving
- Handle missing avatars with a default placeholder image
- Provide clear error messages in admin interface for invalid data
