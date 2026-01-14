# frozen_string_literal: true

module ResourceTypeHelper
  # Type metadata mapping
  TYPE_METADATA = {
    "gems" => {
      name: "Ruby Gems",
      emoji: "💎",
      description: "curated gems for your Ruby projects"
    },
    "books" => {
      name: "Books",
      emoji: "📚",
      description: "curated books to master Ruby and Rails"
    },
    "courses" => {
      name: "Courses",
      emoji: "🎓",
      description: "curated courses to learn Ruby and Rails"
    },
    "tutorials" => {
      name: "Tutorials",
      emoji: "📝",
      description: "curated tutorials for hands-on learning"
    },
    "articles" => {
      name: "Articles",
      emoji: "📰",
      description: "curated articles on Ruby and Rails"
    },
    "tools" => {
      name: "Tools",
      emoji: "🛠️",
      description: "curated tools for Ruby development"
    },
    "podcasts" => {
      name: "Podcasts",
      emoji: "🎙️",
      description: "curated podcasts about Ruby and Rails"
    },
    "communities" => {
      name: "Communities",
      emoji: "👥",
      description: "curated communities to connect with Rubyists"
    },
    # Task 3.2: Newsletter metadata
    "newsletters" => {
      name: "Newsletters",
      emoji: "📧",
      description: "curated newsletters for Ruby developers"
    },
    # Task 3.3: Blog metadata
    "blogs" => {
      name: "Blogs",
      emoji: "📝",
      description: "curated blogs for Ruby developers"
    },
    # Task 3.4: Video metadata
    "videos" => {
      name: "Videos",
      emoji: "🎥",
      description: "curated videos for Ruby developers"
    },
    # Task 3.5: Channel metadata
    "channels" => {
      name: "Channels",
      emoji: "📺",
      description: "curated channels for Ruby developers"
    },
    # Task 3.6: Documentation metadata
    "documentations" => {
      name: "Documentation",
      emoji: "📚",
      description: "curated documentation for Ruby developers"
    },
    # Task 3.7: TestingResource metadata
    "testing-resources" => {
      name: "Testing Resources",
      emoji: "🧪",
      description: "curated testing resources for Ruby developers"
    },
    # Task 3.8: DevelopmentEnvironment metadata
    "development-environments" => {
      name: "Development Environments",
      emoji: "💻",
      description: "curated development environments for Ruby developers"
    },
    # Task 3.9: Job metadata
    "jobs" => {
      name: "Jobs",
      emoji: "💼",
      description: "curated jobs for Ruby developers"
    },
    # Task 3.10: Framework metadata
    "frameworks" => {
      name: "Frameworks",
      emoji: "🏗️",
      description: "curated frameworks for Ruby developers"
    },
    # Task 3.11: Directory metadata
    "directories" => {
      name: "Directories",
      emoji: "📂",
      description: "curated directories for Ruby developers"
    },
    # Task 3.12: Product metadata
    "products" => {
      name: "Products",
      emoji: "🚀",
      description: "curated products for Ruby developers"
    }
  }.freeze

  # Returns human-readable name for a type
  # @param type [String] the type slug (e.g., "gems", "books")
  # @return [String] the human-readable name (e.g., "Ruby Gems", "Books")
  #
  # Example:
  #   type_name("gems") # => "Ruby Gems"
  #   type_name("books") # => "Books"
  def type_name(type)
    TYPE_METADATA.dig(type, :name) || type.titleize
  end

  # Returns emoji for a type
  # @param type [String] the type slug (e.g., "gems", "books")
  # @return [String] the emoji for the type (e.g., "💎", "📚")
  #
  # Example:
  #   type_emoji("gems") # => "💎"
  #   type_emoji("books") # => "📚"
  def type_emoji(type)
    TYPE_METADATA.dig(type, :emoji) || "📦"
  end

  # Returns description/subtitle text for a type browse page
  # @param type [String] the type slug (e.g., "gems", "books")
  # @return [String] the description text
  #
  # Example:
  #   type_description("gems") # => "curated gems for your Ruby projects"
  #   type_description("books") # => "curated books to master Ruby and Rails"
  def type_description(type)
    TYPE_METADATA.dig(type, :description) || "curated #{type} for Ruby developers"
  end

  # Task 3.13: Returns type-specific submission encouragement message
  # @param type [String] the type slug (e.g., "newsletters", "videos")
  # @return [String] the submission message with link
  #
  # Example:
  #   submission_message_for_type("newsletters") # => "Know a great Ruby newsletter? Submit it here"
  #   submission_message_for_type("videos") # => "Know a great Ruby video? Submit it here"
  def submission_message_for_type(type)
    singular_name = singularize_type_name(type)
    "Know a great Ruby #{singular_name}? Submit it here"
  end

  private

  # Converts type slug to singular form for natural language
  # @param type [String] the type slug (e.g., "newsletters", "testing-resources")
  # @return [String] the singular form (e.g., "newsletter", "testing resource")
  def singularize_type_name(type)
    # Handle special cases for multi-word types
    case type
    when "testing-resources"
      "testing resource"
    when "development-environments"
      "development environment"
    when "documentations"
      "documentation"
    else
      # Remove hyphens and singularize
      type.tr("-", " ").singularize
    end
  end
end
