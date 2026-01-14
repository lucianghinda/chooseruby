import { Controller } from "@hotwired/stimulus"

// Provides autocomplete search for existing authors
// Allows selecting an existing author or manually entering a name
export default class extends Controller {
  static targets = ["input", "results", "authorId", "manualInput"]

  connect() {
    this.debounceTimer = null
    this.selectedAuthorId = null

    // Close results when clicking outside
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.boundHandleClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundHandleClickOutside)
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
  }

  // Handle input with debounce to avoid excessive API calls
  handleInput(event) {
    const query = event.target.value.trim()

    // Clear any existing timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    // Hide results if query is empty
    if (query.length === 0) {
      this.hideResults()
      return
    }

    // Debounce search by 300ms
    this.debounceTimer = setTimeout(() => {
      this.searchAuthors(query)
    }, 300)
  }

  // Search for authors via API
  async searchAuthors(query) {
    try {
      this.showLoadingState()

      const response = await fetch(`/authors/search?q=${encodeURIComponent(query)}`, {
        headers: {
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const authors = await response.json()
      this.displayResults(authors)
    } catch (error) {
      console.error("Author search failed:", error)
      this.showError()
    }
  }

  // Display search results
  displayResults(authors) {
    if (authors.length === 0) {
      this.showNoResults()
      return
    }

    const resultsHTML = authors.map(author => {
      const githubInfo = author.github_url ? `<span class="text-xs text-slate-500">${author.github_url}</span>` : ""

      return `
        <button type="button"
                class="w-full text-left px-4 py-3 hover:bg-rose-50 focus:bg-rose-50 focus:outline-none transition"
                data-author-id="${author.id}"
                data-author-name="${this.escapeHtml(author.name)}"
                data-action="click->author-search#selectAuthor">
          <div class="font-medium text-slate-900">${this.escapeHtml(author.name)}</div>
          ${githubInfo}
        </button>
      `
    }).join("")

    this.resultsTarget.innerHTML = resultsHTML
    this.showResults()
  }

  showNoResults() {
    this.resultsTarget.innerHTML = `
      <div class="px-4 py-3 text-sm text-slate-500">
        No matching authors found. Use the manual input field below.
      </div>
    `
    this.showResults()
  }

  showLoadingState() {
    this.resultsTarget.innerHTML = `
      <div class="px-4 py-3 text-sm text-slate-500">
        <span class="inline-flex items-center gap-2">
          <svg class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          Searching...
        </span>
      </div>
    `
    this.showResults()
  }

  showError() {
    this.resultsTarget.innerHTML = `
      <div class="px-4 py-3 text-sm text-rose-600">
        Search failed. Please try again or use manual input.
      </div>
    `
    this.showResults()
  }

  showResults() {
    this.resultsTarget.classList.remove("hidden")
  }

  hideResults() {
    this.resultsTarget.classList.add("hidden")
  }

  // Handle author selection from results
  selectAuthor(event) {
    event.preventDefault()

    const button = event.currentTarget
    const authorId = button.dataset.authorId
    const authorName = button.dataset.authorName

    // Set hidden field value
    if (this.hasAuthorIdTarget) {
      this.authorIdTarget.value = authorId
    }

    // Update search input with selected author name
    if (this.hasInputTarget) {
      this.inputTarget.value = authorName
    }

    // Clear manual input (we're using a selected author)
    if (this.hasManualInputTarget) {
      this.manualInputTarget.value = ""
    }

    // Hide results
    this.hideResults()

    // Announce selection to screen readers
    this.announceSelection(authorName)
  }

  // Handle manual input field changes
  handleManualInput(event) {
    // When user types in manual input, clear the author_id
    if (this.hasAuthorIdTarget) {
      this.authorIdTarget.value = ""
    }

    // Also clear the search input
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
    }
  }

  // Handle clicks outside the component to close results
  handleClickOutside(event) {
    // Check if click is outside the controller element
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  // Announce selection to screen readers
  announceSelection(authorName) {
    let liveRegion = document.getElementById("author-search-announcements")

    if (!liveRegion) {
      liveRegion = document.createElement("div")
      liveRegion.id = "author-search-announcements"
      liveRegion.setAttribute("role", "status")
      liveRegion.setAttribute("aria-live", "polite")
      liveRegion.setAttribute("aria-atomic", "true")
      liveRegion.className = "sr-only"
      document.body.appendChild(liveRegion)
    }

    liveRegion.textContent = `Selected author: ${authorName}`
  }

  // Escape HTML to prevent XSS
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
