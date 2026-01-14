# frozen_string_literal: true

# Configure ActiveHashcash for proof-of-work spam protection
# Documentation: https://github.com/BaseSecrete/active_hashcash

# Set difficulty level (bits) appropriate for form submission
# Lower bits = easier to solve, better UX
# Higher bits = harder to solve, better spam protection
# Default: 20 bits (very difficult)
# Recommended for forms: 12-16 bits for low to medium difficulty
ActiveHashcash.bits = 14

# Note: ActiveHashcash automatically adjusts complexity based on request frequency
# from each IP address, providing adaptive spam protection.
