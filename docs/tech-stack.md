# Tech Stack

## Overview

ChooseRuby uses a modern, vanilla Ruby on Rails stack optimized for simplicity, maintainability, and cost-effectiveness. The technology choices prioritize using Rails' newest built-in capabilities over external dependencies.

## Backend

### Ruby on Rails (Vanilla)

**Choice:** Ruby on Rails 8.x with minimal external dependencies
**Rationale:**

- Rails 8.1 includes batteries (Solid Queue, Solid Cache, Solid Cable) reducing infrastructure complexity
- Vanilla Rails approach keeps codebase maintainable and upgradeable
- Perfect fit for a Ruby ecosystem showcase - dogfooding the latest Rails innovations
- Rapid development for CRUD operations and content management

### SQLite

**Choice:** SQLite as primary database
**Rationale:**

- Rails 8 optimized SQLite for production use with Litestack improvements
- Eliminates separate database server, reducing operational complexity
- Sufficient for read-heavy directory application with moderate write volume
- Simplifies backup (single file), development environment setup, and deployment
- Cost-effective: no managed database service fees

### Active Record

**Choice:** Rails' built-in ORM
**Rationale:**

- Native Rails integration with conventions we're already following
- Excellent for straightforward relational data model (resources, categories, users)
- Built-in association management, validations, and query interface
- No learning curve - standard Rails development

## Background Processing

### Solid Queue

**Choice:** Rails 8's built-in background job processor
**Rationale:**

- Eliminates Redis dependency and separate job processor infrastructure
- Stores jobs in SQLite, maintaining single-database architecture
- Handles email sending, resource processing, and batch operations
- Zero configuration for development and production parity
- Part of Rails 8 mission to simplify deployment

## Caching

### Solid Cache

**Choice:** Rails 8's built-in caching library
**Rationale:**

- Database-backed caching using SQLite, no Redis required
- Ideal for caching search results, rendered resource cards, and category pages
- Consistent with single-database architecture philosophy
- Automatic cache expiration and cleanup handled by the library

## Frontend

### Stimulus

**Choice:** Hotwire Stimulus for JavaScript interactivity
**Rationale:**

- Minimal JavaScript framework aligned with Rails conventions
- Perfect for progressive enhancement (search autocomplete, filters, form interactions)
- Keeps most logic server-side, reducing frontend complexity
- Small footprint, fast page loads
- Native Rails integration via Hotwire

### Turbo

**Choice:** Hotwire Turbo for SPA-like navigation
**Rationale:**

- Fast navigation without full page reloads
- Turbo Frames for partial page updates (search results, filtering)
- Turbo Streams for real-time updates if needed
- Included with Rails by default

### Tailwind CSS

**Choice:** Tailwind for styling
**Rationale:**

- Utility-first approach speeds up UI development
- Highly customizable for creating unique brand identity
- Responsive design built-in for mobile-friendly directory
- Small production bundle with PurgeCSS
- Active community with Ruby/Rails integration

## Testing

### Minitest

**Choice:** Rails' default testing framework
**Rationale:**

- Fast, lightweight, and built into Rails
- Sufficient for application testing needs (models, controllers, system tests)
- Consistent with vanilla Rails philosophy
- Lower learning curve for Rails developers

### System Tests with Selenium

**Choice:** Rails system tests for end-to-end testing
**Rationale:**

- Verify critical user flows (search, submission, curation)
- Built into Rails testing infrastructure
- Tests real browser interactions with Stimulus controllers

## Code Quality

### Rubocop

**Choice:** Rubocop for linting and formatting
**Rationale:**

- De facto standard for Ruby code style enforcement
- Automatic formatting catches issues before code review
- Configurable rules to match project conventions
- Integrates with CI/CD pipeline

## Email

### MailerSend

**Choice:** MailerSend for transactional emails
**Rationale:**

- Reliable delivery for submission notifications and user emails
- Simple API integration with Action Mailer
- Generous free tier for MVP launch
- Analytics and deliverability monitoring
- SMTP or API delivery options

## Deployment

### Hatchbox

**Choice:** Hatchbox for application hosting
**Rationale:**

- Rails-optimized deployment platform
- Automated deploys from GitHub with zero-downtime releases
- Built-in server management, SSL, and monitoring
- Cost-effective alternative to Heroku with more control
- Supports SQLite-based Rails 8 applications
- Simple scaling when needed

### GitHub Actions

**Choice:** GitHub Actions for CI/CD
**Rationale:**

- Integrated with code repository for seamless workflow
- Run tests and Rubocop on every pull request
- Automated deployment to Hatchbox on main branch merges
- Free for public repositories
- Wide range of pre-built actions for Ruby/Rails

## Development Tools

### Docker (Optional)

**Choice:** Docker for consistent development environments
**Rationale:**

- Ensures all developers and CI have identical Ruby/Rails versions
- Simplifies onboarding for new contributors
- Optional - SQLite and Rails 8 minimize local dependencies

## Architecture Principles

### Single Database Philosophy

All persistent data (application data, job queue, cache) lives in SQLite. This radically simplifies:

- Infrastructure: one database file instead of PostgreSQL + Redis
- Backups: copy a single file
- Development: no service orchestration
- Costs: no managed service fees

### Server-Side Rendering First

HTML rendered server-side with Rails views and Turbo for dynamic updates. JavaScript (Stimulus) adds interactivity progressively. This delivers:

- Fast initial page loads
- Better SEO for resource discovery
- Simpler debugging (most logic in Ruby)
- Accessible by default

### Convention Over Configuration

Vanilla Rails conventions throughout. Minimal custom configuration, preferring Rails defaults. This ensures:

- Faster onboarding for Rails developers
- Easier upgrades to new Rails versions
- Reduced maintenance burden
- Aligned with Rails 8 philosophy

## Scalability Considerations

### When SQLite Becomes a Bottleneck

The application can scale significantly on SQLite due to read-heavy workload (directory browsing). If write volume increases beyond SQLite capacity:

- Migrate to PostgreSQL (Active Record makes this straightforward)
- Move to Redis for Solid Queue/Cache
- Database design prepared for this transition

### Horizontal Scaling

Hatchbox supports adding application servers behind load balancer. SQLite's single-writer limitation can be addressed by:

- Read replicas for search and directory pages
- PostgreSQL migration for multi-writer scenarios
- Caching strategy reduces database load

## Security

- **Authentication:** Use Rails 8 built-in authentication
- **Authorization:** Pundit for role-based access control (admin curation)
- **Input Validation:** Strong Parameters and Active Record validations
- **XSS Protection:** Rails' automatic HTML escaping
- **CSRF Protection:** Built-in Rails CSRF tokens
- **SQL Injection:** Parameterized queries via Active Record
- **Rate Limiting:** Rack Attack for API and submission endpoints

## Monitoring and Observability

- **Error Tracking:** Use gem solid_errors and send notifications via MailerSend
- **Performance Monitoring:** Rails built-in logging and Hatchbox monitoring
- **Uptime Monitoring:** Simple uptime checker (UptimeRobot, Pingdom)
- **Analytics:** Privacy-friendly analytics (Tinylytics) for usage insights
