import { Controller } from "@hotwired/stimulus"

// Shows a floating scroll-to-top/search button after scrolling, and focuses the
// homepage search input on demand.
export default class extends Controller {
  static targets = ["button"]
  static values = { threshold: { type: Number, default: 400 } }

  connect() {
    this.onScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.updateVisibility()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  onScroll() {
    this.updateVisibility()
  }

  updateVisibility() {
    if (!this.hasButtonTarget) return
    const shouldShow = window.scrollY >= this.thresholdValue
    this.buttonTarget.classList.toggle("opacity-0", !shouldShow)
    this.buttonTarget.classList.toggle("translate-y-3", !shouldShow)
    this.buttonTarget.classList.toggle("pointer-events-none", !shouldShow)
  }

  scrollToTop(event) {
    event?.preventDefault()
    window.scrollTo({ top: 0, behavior: "smooth" })
    window.setTimeout(() => this.focusSearch(), 150)
  }

  focusSearch(event) {
    event?.preventDefault()
    const searchInput = document.getElementById("home-search-input")
    if (!searchInput) return

    searchInput.focus({ preventScroll: true })
    searchInput.scrollIntoView({ behavior: "smooth", block: "center" })
  }
}
