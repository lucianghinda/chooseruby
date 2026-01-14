import { Controller } from "@hotwired/stimulus"

// Inline typeahead with keyboard navigation, recent searches (localStorage),
// and popular query suggestions passed via data attribute.
export default class extends Controller {
  static targets = ["input", "panel", "results", "option", "status"]
  static values = { url: String, popular: Array }

  connect() {
    this.debounceTimer = null
    this.activeIndex = -1
    this.recentKey = "chooseruby_recent_searches"
  }

  search() {
    const query = this.inputTarget.value.trim()
    clearTimeout(this.debounceTimer)

    if (query.length < 2) {
      this.renderLocalSuggestions()
      return
    }

    this.debounceTimer = setTimeout(() => this.fetchSuggestions(query), 180)
  }

  focus() {
    if (this.inputTarget.value.trim().length < 2) {
      this.renderLocalSuggestions()
      return
    }

    if (this.resultsTarget.innerHTML.trim().length > 0) {
      this.show()
    }
  }

  blur() {
    setTimeout(() => this.hide(), 120)
  }

  navigate(event) {
    if (this.panelTarget.classList.contains("hidden")) return
    if (!["ArrowDown", "ArrowUp", "Enter", "Escape"].includes(event.key)) return

    const options = this.optionTargets
    if (!options.length) return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.moveHighlight(1)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.moveHighlight(-1)
    } else if (event.key === "Enter") {
      if (this.activeIndex >= 0 && this.activeIndex < options.length) {
        event.preventDefault()
        this.selectOption(options[this.activeIndex])
      }
    } else if (event.key === "Escape") {
      this.hide()
      this.inputTarget.focus()
    }
  }

  optionClicked(event) {
    const option = event.currentTarget
    const query = option.dataset.query || this.inputTarget.value.trim()
    if (query) this.storeRecent(query)

    const optionQuery = option.dataset.query
    if (optionQuery) {
      event.preventDefault()
      this.inputTarget.value = optionQuery
      this.element.requestSubmit()
    }
  }

  optionKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.optionClicked(event)
    } else if (event.key === "Escape") {
      this.hide()
      this.inputTarget.focus()
    }
  }

  recordSearch(event) {
    const query = this.inputTarget.value.trim()
    if (query.length >= 2) this.storeRecent(query)
  }

  clear() {
    this.inputTarget.value = ""
    this.hide()
    this.inputTarget.focus()
  }

  show() {
    this.panelTarget.classList.remove("hidden")
    this.inputTarget.setAttribute("aria-expanded", "true")
  }

  hide() {
    this.panelTarget.classList.add("hidden")
    this.resultsTarget.innerHTML = ""
    this.activeIndex = -1
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.announce("")
  }

  fetchSuggestions(query) {
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("q", query)

    fetch(url.toString(), { headers: { Accept: "text/html" } })
      .then((response) => response.text())
      .then((html) => {
        this.resultsTarget.innerHTML = html
        const hasContent = html.trim().length > 0
        this.panelTarget.classList.toggle("hidden", !hasContent)
        this.activeIndex = -1
        this.announce(hasContent ? "Suggestions updated" : "No suggestions")
      })
      .catch(() => this.hide())
  }

  moveHighlight(delta) {
    const options = this.optionTargets
    if (!options.length) return

    this.activeIndex = (this.activeIndex + delta + options.length) % options.length
    options.forEach((option, idx) => {
      const isActive = idx === this.activeIndex
      option.classList.toggle("bg-slate-100", isActive)
      option.setAttribute("aria-selected", isActive)
      if (isActive) option.focus()
    })
  }

  renderLocalSuggestions() {
    const recent = this.loadRecent()
    const popular = this.popularValue || []
    if (!recent.length && !popular.length) {
      this.hide()
      return
    }

    const recentHtml = recent.length
      ? `
        <div class="px-4 py-3">
          <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Recent searches</p>
          <div class="mt-2 flex flex-wrap gap-2">
            ${recent
              .map(
                (term) => `
                  <button type="button"
                          class="inline-flex items-center gap-2 rounded-full bg-slate-100 px-3 py-1 text-[11px] font-semibold text-slate-700 transition hover:bg-slate-200 focus:bg-slate-200 focus:outline-none"
                          data-typeahead-target="option"
                          data-query="${term}"
                          data-action="mousedown->typeahead#optionClicked keydown->typeahead#optionKeydown"
                          role="option">
                    ${term}
                  </button>
                `,
              )
              .join("")}
          </div>
        </div>
      `
      : ""

    const popularHtml = popular.length
      ? `
        <div class="px-4 py-3">
          <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Popular searches</p>
          <div class="mt-2 flex flex-wrap gap-2">
            ${popular
              .map(
                (term) => `
                  <button type="button"
                          class="inline-flex items-center gap-2 rounded-full bg-slate-900 px-3 py-1 text-[11px] font-semibold text-white transition hover:bg-slate-800 focus:bg-slate-800 focus:outline-none"
                          data-typeahead-target="option"
                          data-query="${term}"
                          data-action="mousedown->typeahead#optionClicked keydown->typeahead#optionKeydown"
                          role="option">
                    ${term}
                  </button>
                `,
              )
              .join("")}
          </div>
        </div>
      `
      : ""

    this.resultsTarget.innerHTML = `${recentHtml}${popularHtml}`
    this.show()
    this.activeIndex = -1
    this.announce("Suggestions updated")
  }

  storeRecent(query) {
    const list = this.loadRecent().filter((q) => q.toLowerCase() !== query.toLowerCase())
    list.unshift(query)
    const trimmed = list.slice(0, 5)
    localStorage.setItem(this.recentKey, JSON.stringify(trimmed))
  }

  loadRecent() {
    try {
      const data = localStorage.getItem(this.recentKey)
      if (!data) return []
      return JSON.parse(data)
    } catch (error) {
      return []
    }
  }

  announce(message) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = message
  }
}
